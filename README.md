# Open Source AI Engine
 
- 100% open source, serves AI models via a REST interface
- Runs open source models locally (using Ollama), and on the cloud (Fly + Supabase)
- Wraps popular closed models
- Stores queries/responses in Postgres for training
- Secure by default
- Is as simple as possible

## Usage

- `ollama run llama2`
- `supabase start`


Then make a request to the `proxy` function:

```bash
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/proxy' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
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
```

This will store the data in the database for later training.

![History](docs/image.png)