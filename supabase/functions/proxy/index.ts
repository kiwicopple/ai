// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/proxy' \
    --header 'Content-Type: application/json' \
    --header 'x-org-id: org_2cribTfm5N1T2Ac9qH2Xc48pE0k' \
    --data '{
        "model": "llama2",
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant."
            },
            {
                "role": "user",
                "content": "Hello!"
            }
        ]
    }'

*/
// import { createClient } from "https://esm.sh/@supabase/supabase-js";
import * as postgres from "https://deno.land/x/postgres@v0.17.0/mod.ts";

const POSTGRES_URL = Deno.env.get("SUPABASE_DB_URL")!;
const OLLAMA_URL = "http://host.docker.internal:11434/v1/chat/completions";

// Create a database pool with three connections that are lazily established
const pool = new postgres.Pool(POSTGRES_URL, 3, true);

Deno.serve(async (req) => {
  const connection = await pool.connect();
  try {
    const input = await req.json();
    const secretKey = req.headers.get("Authorization")?.replace("Bearer ", "");

    // Validate the key
    type keyDataType = { id: string; organization_id: string };
    const result = await connection.queryObject<keyDataType>`
      select id, organization_id
      from private.keys
      where active = true and id = ${secretKey}
      limit 1
    `;
    const keyData = result.rows[0];
    if (!keyData) {
      throw new Error("Invalid key.");
    }

    // Pass the request to Ollama
    const res = await fetch(
      OLLAMA_URL,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model: input.model,
          messages: input.messages,
        }),
      },
    );
    const data = await res.json();

    // Store the request for use to train on
    const model = input.model;
    const organization_id = keyData.organization_id;
    const logQuery = await connection.queryObject<{ id: string }>`
      insert into private.requests (model, organization_id, input, response, key_id)
      values (
        ${model},
        ${organization_id},
        ${input},
        ${data},
        ${secretKey}
      )
      returning id;
    `;
    const log = logQuery.rows[0];
    console.log("log", log);

    // Return the response to the user
    const logId = log?.id ?? null;
    const response = JSON.stringify({ ...data, id: logId });
    const options = { headers: { "Content-Type": "application/json" } };
    return new Response(response, options);
  } catch (err) {
    console.log("err", err);
    const error = String(err?.message ?? err);
    return new Response(JSON.stringify({ error }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  } finally {
    connection.release();
  }
});
