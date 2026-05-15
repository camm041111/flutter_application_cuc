# Forum Push Notification

Esta Edge Function procesa una respuesta nueva de `respuestas_foro`, crea una
fila en `notificaciones` para el autor de la pregunta y manda push por FCM si
el usuario tiene tokens activos en `tokens_push`.

## Secretos requeridos

Configuralos en Supabase, no dentro del repo:

```bash
supabase secrets set FIREBASE_PROJECT_ID="tu-project-id"
supabase secrets set FIREBASE_CLIENT_EMAIL="firebase-adminsdk-...@....iam.gserviceaccount.com"
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

`SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` los inyecta Supabase al ejecutar
la funcion desplegada.

## Despliegue

```bash
supabase functions deploy forum-push-notification
```

Luego conecta la tabla `respuestas_foro` con esta funcion usando un Database
Webhook de Supabase:

- Table: `respuestas_foro`
- Events: `Insert`
- Type: `Supabase Edge Function`
- Function: `forum-push-notification`
