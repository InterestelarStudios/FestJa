# Cloud Functions - Notificações Fest'Ja

Este diretório contém o backend serverless do **Fest'Ja** responsável pelo envio automático de Push Notifications (FCM) e agendamento de lembretes (Cron).

## 🚀 Funções Implementadas

| Função | Tipo / Gatilho | Descrição |
|---|---|---|
| `onBookingCreated` | Firestore `bookings/{id}` onCreate | Notifica a **empresa** nativamente e in-app quando um cliente envia uma solicitação de reserva/proposta. |
| `onBookingStatusUpdated` | Firestore `bookings/{id}` onUpdate | Notifica o **cliente** nativamente e in-app quando a empresa aprova ou recusa a reserva. |
| `onNewChatMessage` | Firestore `chats/{chatId}/messages/{id}` onCreate | Notifica o outro participante quando uma nova mensagem é enviada no chat. |
| `eventReminderCron` | Cron Agendado (`0 9 * * *` - Diário às 09:00) | Identifica eventos nas próximas 24-48h e envia lembrete ao organizador e aos prestadores. |
| `sendBroadcastPush` | Callable HTTPS | Permite envio de pushes segmentados ou globais para tópicos (ex: `all_clients`, `all_businesses`). |

---

## 🛠️ Como Instalar e Fazer o Deploy

### 1. Pré-requisitos
- Node.js versão 18 ou superior instalado.
- Firebase CLI instalado globalmente:
  ```bash
  npm install -g firebase-tools
  ```
- Projeto Firebase com o plano **Blaze (Pay-as-you-go)** ativo para executar Cloud Functions.

### 2. Instalação das dependências
Abra o terminal no diretório `functions`:
```bash
cd functions
npm install
```

### 3. Login e Deploy
```bash
firebase login
firebase use --add  # Selecione o projeto do Firebase onde estão os apps
firebase deploy --only functions
```

### 4. Visualizar Logs em tempo real
```bash
firebase functions:log
```
