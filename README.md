# lumio-ai-support-chat

LumioAPI 的浏览器安全 AI 客服网关。前端只调用本服务，本服务在服务端注入私密的 DocsGPT Agent API Key，并把 DocsGPT 的 SSE 流式响应转发给浏览器。

## 功能

- `GET /healthz`：健康检查。
- `GET /widget-config?locale=zh-CN|zh-Hant|en-US`：返回公开客服组件配置，不包含密钥。
- `POST /chat/stream`：接收用户问题，转发到 DocsGPT `/stream`，并返回 `text/event-stream`。

## Zeabur 部署

本仓库根目录已包含 `Dockerfile`。Zeabur 会自动检测 `Dockerfile` 并按 Docker 服务部署；环境变量可在 Zeabur 服务的 Variables/环境变量页面配置。参考 Zeabur 官方文档：[Dockerfile 部署](https://zeabur.com/docs/en-US/deploy/methods/dockerfile)、[环境变量](https://zeabur.com/docs/en-US/deploy/config/environment-variables)。

1. 在 Zeabur 项目中创建一个 GitHub/Git 服务，选择本仓库和部署分支。
2. 确认 Root Directory 使用仓库根目录，Zeabur 会使用根目录的 `Dockerfile`。
3. 在服务环境变量中配置：

```bash
DOCSGPT_API_BASE_URL=https://your-docsgpt-service
DOCSGPT_AGENT_API_KEY=your-docsgpt-agent-key
ALLOWED_ORIGINS=https://your-lumio-frontend.com
SUPPORT_EMAIL=support@example.com
SUPPORT_URL=https://your-support-page.com
RATE_LIMIT_WINDOW_SECONDS=60
RATE_LIMIT_MAX_REQUESTS=20
```

`PORT` 通常由 Zeabur 注入；本服务未设置时默认监听 `8080`。如果手动配置端口，请使用 `PORT=8080`，并保持 Dockerfile 中的 `EXPOSE 8080` 一致。

可选客服文案覆盖：

```bash
WIDGET_TITLE=
WELCOME_MESSAGE=
OFFICIAL_CONTACT_TEXT=
```

4. 部署完成后，在 Zeabur 绑定或复制公网域名，例如 `https://your-service.zeabur.app`。
5. 验证健康检查：

```bash
curl https://your-service.zeabur.app/healthz
```

预期返回：

```json
{"ok":true}
```

## 前端使用

前端只保存 Zeabur 服务域名，不要保存 `DOCSGPT_AGENT_API_KEY`。

获取组件配置：

```bash
curl "https://your-service.zeabur.app/widget-config?locale=zh-CN"
```

发送聊天请求并读取 SSE：

```bash
curl -N -X POST "https://your-service.zeabur.app/chat/stream" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{
    "message": "如何充值？",
    "conversationId": "optional-docsgpt-conversation-id",
    "locale": "zh-CN",
    "user": { "id": "optional-user-id", "email": "user@example.com" }
  }'
```

支持的常用 `locale`：`zh-CN`、`zh-Hant`、`en-US`。如果未设置 `WIDGET_TITLE`、`WELCOME_MESSAGE`、`OFFICIAL_CONTACT_TEXT`，`/widget-config` 会按 locale 返回默认文案。

## 本地开发与验证

```bash
cp .env.example .env
go test ./...
go run .
```

本地默认监听 `http://localhost:8080`。如果浏览器前端在本地调试，请把该前端地址加入 `ALLOWED_ORIGINS`，例如 `http://localhost:5174`。

## 配置说明

- `DOCSGPT_API_BASE_URL`：DocsGPT 服务地址，不要以 `/` 结尾。
- `DOCSGPT_AGENT_API_KEY`：DocsGPT Agent API Key，只能配置在网关服务端。
- `ALLOWED_ORIGINS`：允许调用网关的浏览器来源，多个值用英文逗号分隔；生产环境不要使用 `*`。
- `SUPPORT_EMAIL` / `SUPPORT_URL`：官方人工支持入口，会返回给客服组件。
- `RATE_LIMIT_WINDOW_SECONDS` / `RATE_LIMIT_MAX_REQUESTS`：按客户端 IP 限制 `/chat/stream` 请求频率。

## 关键文件

- `main.go`：进程入口和端口绑定。
- `config.go`：环境变量读取、清洗和必填校验。
- `server.go`：CORS、限流、公开组件配置、DocsGPT 请求构造、SSE 转发。
- `server_test.go`：覆盖密钥隔离、locale 透传、CORS、SSE 转发和限流。
- `docs/`：DocsGPT 支持代理和整体架构说明。
