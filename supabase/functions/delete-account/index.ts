import { createClient } from 'npm:@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const authorization = request.headers.get('Authorization')
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceRoleKey = Deno.env.get('VGA_SERVICE_ROLE_KEY')

  if (!authorization || !supabaseUrl || !serviceRoleKey) {
    return Response.json(
      { error: 'Missing function configuration.' },
      { status: 500, headers: corsHeaders },
    )
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })

  const jwt = authorization.replace('Bearer ', '').trim()
  const {
    data: { user },
    error: userError,
  } = await admin.auth.getUser(jwt)

  if (userError || user == null) {
    return Response.json(
      { error: 'Unable to identify the authenticated user.' },
      { status: 401, headers: corsHeaders },
    )
  }

  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id)
  if (deleteError != null) {
    return Response.json(
      { error: deleteError.message },
      { status: 500, headers: corsHeaders },
    )
  }

  return Response.json(
    { success: true },
    { status: 200, headers: corsHeaders },
  )
})
