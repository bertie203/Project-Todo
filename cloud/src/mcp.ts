// Minimal stateless MCP server over Streamable HTTP (JSON responses only).
// Handles initialize, ping, tools/list and tools/call.

import { tools, type ToolContext } from './tools';

const SUPPORTED_VERSIONS = ['2026-07-28', '2025-11-25', '2025-06-18', '2025-03-26'];

const INSTRUCTIONS = `This connector is the user's personal to-do list from their Project Todo phone app.
When the user asks what they are doing today, wants to plan their day, or says "let's get cracking", call todays_plan first, then work through the tasks with them: suggest an order (red priority and late tasks first), mark tasks done with complete_task when they say they have finished, and reschedule with update_task when they want to move something.
Refer to tasks by title when talking to the user; the bracketed ids are for tool calls only.
Dates are YYYY-MM-DD and times HH:MM in the user's local time zone, which todays_plan reports.
Changes appear on the user's phone the next time the app syncs.`;

interface RpcRequest {
  jsonrpc: '2.0';
  id?: string | number | null;
  method: string;
  params?: any;
}

function result(id: RpcRequest['id'], value: unknown) {
  return { jsonrpc: '2.0', id, result: value };
}

function error(id: RpcRequest['id'], code: number, message: string) {
  return { jsonrpc: '2.0', id: id ?? null, error: { code, message } };
}

async function handleOne(req: RpcRequest, ctx: ToolContext): Promise<object | null> {
  const isNotification = req.id === undefined;
  switch (req.method) {
    case 'initialize': {
      const asked = req.params?.protocolVersion;
      return result(req.id, {
        protocolVersion: SUPPORTED_VERSIONS.includes(asked) ? asked : SUPPORTED_VERSIONS[0],
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: 'project-todo', title: 'Project Todo', version: '0.1.0' },
        instructions: INSTRUCTIONS,
      });
    }
    case 'ping':
      return result(req.id, {});
    case 'tools/list':
      return result(req.id, {
        tools: tools.map((t) => ({
          name: t.name,
          description: t.description,
          inputSchema: t.inputSchema,
          annotations: { readOnlyHint: !!t.readOnly, destructiveHint: t.name === 'delete_task' },
        })),
      });
    case 'tools/call': {
      const tool = tools.find((t) => t.name === req.params?.name);
      if (!tool) return error(req.id, -32602, `Unknown tool: ${req.params?.name}`);
      try {
        const text = await tool.run(req.params?.arguments ?? {}, ctx);
        return result(req.id, { content: [{ type: 'text', text }] });
      } catch (e) {
        // Tool errors go back to the model so it can correct itself.
        return result(req.id, {
          content: [{ type: 'text', text: `Error: ${e instanceof Error ? e.message : String(e)}` }],
          isError: true,
        });
      }
    }
    default:
      if (isNotification) return null;
      return error(req.id, -32601, `Method not found: ${req.method}`);
  }
}

export async function handleMcp(request: Request, ctx: ToolContext): Promise<Response> {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405, headers: { Allow: 'POST' } });
  }
  let body: RpcRequest | RpcRequest[];
  try {
    body = await request.json();
  } catch {
    return Response.json(error(null, -32700, 'Parse error'), { status: 400 });
  }
  const batch = Array.isArray(body);
  const list: RpcRequest[] = Array.isArray(body) ? body : [body];
  const replies = (await Promise.all(list.map((r) => handleOne(r, ctx)))).filter(
    (r): r is object => r !== null,
  );
  if (replies.length === 0) return new Response(null, { status: 202 });
  return Response.json(batch ? replies : replies[0]);
}
