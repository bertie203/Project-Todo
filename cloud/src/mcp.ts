// Minimal stateless MCP server over Streamable HTTP (JSON responses only).
// Handles initialize, ping, tools/list and tools/call.

import { tools, type ToolContext } from './tools';

const SUPPORTED_VERSIONS = ['2026-07-28', '2025-11-25', '2025-06-18', '2025-03-26'];

const INSTRUCTIONS = `This connector is the user's personal to-do list from their Project Todo phone app.

Whenever the user asks about a single day (today, tomorrow, a weekday, "let's get cracking"), call day_plan for that date. Then answer with a short PLAN, not a copy of the list:
1. Anchors: the fixed-time tasks in time order. Mention alarms. If a time has already passed today, say so and offer to move it.
2. Suggested order for everything else, as a numbered list: late tasks first (say how late), then red, orange, green. Keep tasks from the same project together to save switching, and fit them into the gaps around the anchors (e.g. "before 13:20", "after lunch").
3. One line on load, e.g. "4 tasks, mostly Fetchleads", and flag anything that looks too much for one day or has been late for several days; offer to move some.
4. End with one short question to tailor the plan, such as how much time they have or whether anything else is fixed that day. Do not ask more than one.
Keep it brief: no headings, no ids, no restating every field. Refer to tasks by title; the bracketed ids are only for tool calls.

While working through the day: when the user says they finished something, call complete_task. When they want to move something, call update_task with the new due_date and/or due_time. After changes, give a one-line update on what is left rather than the full plan again.

Dates are YYYY-MM-DD and times HH:MM in the user's local time zone, which day_plan reports. Changes appear on the user's phone the next time the app syncs.`;

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
