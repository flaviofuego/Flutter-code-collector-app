import express from "express";
import swaggerUi from "swagger-ui-express";
import swaggerSpec from "./swagger.config";
import authRouter from "./routes/auth";
import taskRouter from "./routes/task";

const app = express();

app.use(express.json());

// Swagger UI
app.use("/api-docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec, {
  customCss: '.swagger-ui .topbar { display: none }',
  customSiteTitle: "Task Manager API Docs",
}));

// Swagger JSON
app.get("/api-docs.json", (req, res) => {
  res.setHeader("Content-Type", "application/json");
  res.send(swaggerSpec);
});

app.use("/auth", authRouter);
app.use("/tasks", taskRouter);

app.get("/", (req, res) => {
  res.send(`
    <html>
      <head>
        <title>Task Manager API</title>
        <style>
          body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
          }
          .container {
            background: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
          }
          h1 {
            color: #333;
          }
          a {
            display: inline-block;
            margin: 10px 0;
            padding: 12px 24px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
          }
          a:hover {
            background: #0056b3;
          }
          .info {
            margin: 20px 0;
            padding: 15px;
            background: #e7f3ff;
            border-left: 4px solid #2196F3;
          }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>🚀 Task Manager API</h1>
          <p>Bienvenido al API de Task Manager - Sistema de gestión de tareas con soporte offline-first</p>
          
          <div class="info">
            <strong>Documentación API:</strong>
            <br/>
            <a href="/api-docs" target="_blank">📚 Ver Documentación Swagger</a>
          </div>
          
          <h3>Endpoints disponibles:</h3>
          <ul>
            <li><strong>Auth:</strong> /auth/signup, /auth/login, /auth/tokenIsValid, /auth</li>
            <li><strong>Tasks:</strong> /tasks (GET, POST, DELETE), /tasks/sync</li>
          </ul>
          
          <p><em>Versión 1.0.0</em></p>
        </div>
      </body>
    </html>
  `);
});

app.listen(8000, () => {
  console.log("Server started on port 8000");
  console.log("📚 Swagger UI: http://localhost:8000/api-docs");
});
