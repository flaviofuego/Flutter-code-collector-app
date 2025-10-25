import swaggerJsdoc from 'swagger-jsdoc';

const options: swaggerJsdoc.Options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Task Manager API',
      version: '1.0.0',
      description: 'API para gestión de tareas con soporte offline-first. Backend con Node.js, Express, TypeScript y PostgreSQL.',
      contact: {
        name: 'API Support',
        email: 'support@taskmanager.com',
      },
    },
    servers: [
      {
        url: 'http://localhost:8000',
        description: 'Servidor de desarrollo',
      },
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'apiKey',
          in: 'header',
          name: 'x-auth-token',
          description: 'Token JWT obtenido del login',
        },
      },
      schemas: {
        User: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'ID único del usuario',
            },
            name: {
              type: 'string',
              description: 'Nombre del usuario',
            },
            email: {
              type: 'string',
              format: 'email',
              description: 'Email del usuario',
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de creación',
            },
            updatedAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de última actualización',
            },
          },
        },
        Task: {
          type: 'object',
          properties: {
            id: {
              type: 'string',
              description: 'ID único de la tarea',
            },
            title: {
              type: 'string',
              description: 'Título de la tarea',
            },
            description: {
              type: 'string',
              description: 'Descripción de la tarea',
            },
            dueAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de vencimiento',
            },
            color: {
              type: 'string',
              description: 'Color de la tarea (hex)',
            },
            uid: {
              type: 'string',
              description: 'ID del usuario propietario',
            },
            createdAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de creación',
            },
            updatedAt: {
              type: 'string',
              format: 'date-time',
              description: 'Fecha de última actualización',
            },
          },
        },
        SignUpRequest: {
          type: 'object',
          required: ['name', 'email', 'password'],
          properties: {
            name: {
              type: 'string',
              example: 'Juan Pérez',
            },
            email: {
              type: 'string',
              format: 'email',
              example: 'juan@example.com',
            },
            password: {
              type: 'string',
              format: 'password',
              example: 'password123',
            },
          },
        },
        LoginRequest: {
          type: 'object',
          required: ['email', 'password'],
          properties: {
            email: {
              type: 'string',
              format: 'email',
              example: 'juan@example.com',
            },
            password: {
              type: 'string',
              format: 'password',
              example: 'password123',
            },
          },
        },
        LoginResponse: {
          type: 'object',
          properties: {
            token: {
              type: 'string',
              description: 'Token JWT para autenticación',
            },
            id: {
              type: 'string',
            },
            name: {
              type: 'string',
            },
            email: {
              type: 'string',
            },
          },
        },
        CreateTaskRequest: {
          type: 'object',
          required: ['title', 'dueAt'],
          properties: {
            title: {
              type: 'string',
              example: 'Completar proyecto',
            },
            description: {
              type: 'string',
              example: 'Terminar el desarrollo del API',
            },
            dueAt: {
              type: 'string',
              format: 'date-time',
              example: '2025-10-30T10:00:00Z',
            },
            color: {
              type: 'string',
              example: '#FF5733',
            },
          },
        },
        DeleteTaskRequest: {
          type: 'object',
          required: ['taskId'],
          properties: {
            taskId: {
              type: 'string',
              example: 'abc123xyz',
            },
          },
        },
        Error: {
          type: 'object',
          properties: {
            error: {
              type: 'string',
              description: 'Mensaje de error',
            },
          },
        },
      },
    },
    tags: [
      {
        name: 'Auth',
        description: 'Endpoints de autenticación',
      },
      {
        name: 'Tasks',
        description: 'Endpoints de gestión de tareas',
      },
    ],
  },
  apis: ['./src/routes/*.ts'], // Path a los archivos con las rutas
};

const swaggerSpec = swaggerJsdoc(options);

export default swaggerSpec;
