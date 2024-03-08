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

// Get the connection string from the environment variable "SUPABASE_DB_URL"
const databaseUrl = Deno.env.get("SUPABASE_DB_URL")!;

// Create a database pool with three connections that are lazily established
const pool = new postgres.Pool(databaseUrl, 3, true);

Deno.serve(async (req) => {
  const connection = await pool.connect();
  try {
    const input = await req.json();

    // Run a query
    const result = await connection.queryObject`
        select * 
        from private.keys
      `;
    const keys = result.rows;

    // Encode the result as pretty printed JSON
    const body = JSON.stringify(
      keys,
      (k, value) => (typeof value === "bigint" ? value.toString() : value),
      2,
    );

    console.log("body", body);

    // // Authenticate the API Token
    // const { error: keyError } = await supabase
    //   .from("keys")
    //   .select("id")
    //   .match({
    //     "id": req.headers.get("Authorization")!,
    //     "organization_id": req.headers.get("x-org-id"), // temporary
    //   })
    //   .maybeSingle();

    // if (keyError) throw keyError;

    // Pass the request to Ollama on http://localhost:11434/v1/chat/completions
    const res = await fetch(
      "http://host.docker.internal:11434/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(input),
      },
    );
    const data = await res.json();

    // // Store the response in the database
    // const { data: history, error } = await supabase
    //   .from("requests")
    //   .insert({
    //     model: input.model,
    //     organization_id: req.headers.get("x-org-id"),
    //     input,
    //     response: data,
    //   })
    //   .select("id")
    //   .maybeSingle();
    // if (error) throw error;

    // Return the response to the user
    return new Response(
      JSON.stringify({
        ...data,
        // id: history?.id ?? null,
      }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    console.log("err", err);
    return new Response(String(err?.message ?? err), { status: 500 });
  } finally {
    // Release the connection back into the pool
    connection.release();
  }
});
