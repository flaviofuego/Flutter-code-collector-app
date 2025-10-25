import { Router } from "express";
import { auth, AuthRequest } from "../middleware/auth";
import { NewTask, tasks } from "../db/schema";
import { db } from "../db";
import { eq } from "drizzle-orm";

const taskRouter = Router();

/**
 * @swagger
 * /tasks:
 *   post:
 *     tags:
 *       - Tasks
 *     summary: Crear una nueva tarea
 *     description: Crea una nueva tarea para el usuario autenticado
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/CreateTaskRequest'
 *     responses:
 *       201:
 *         description: Tarea creada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Task'
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
taskRouter.post("/", auth, async (req: AuthRequest, res) => {
  try {
    req.body = { ...req.body, dueAt: new Date(req.body.dueAt), uid: req.user };
    const newTask: NewTask = req.body;

    const [task] = await db.insert(tasks).values(newTask).returning();

    res.status(201).json(task);
  } catch (e) {
    res.status(500).json({ error: e });
  }
});

/**
 * @swagger
 * /tasks:
 *   get:
 *     tags:
 *       - Tasks
 *     summary: Obtener todas las tareas
 *     description: Retorna todas las tareas del usuario autenticado
 *     security:
 *       - BearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de tareas
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Task'
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
taskRouter.get("/", auth, async (req: AuthRequest, res) => {
  try {
    const allTasks = await db
      .select()
      .from(tasks)
      .where(eq(tasks.uid, req.user!));

    res.json(allTasks);
  } catch (e) {
    res.status(500).json({ error: e });
  }
});

/**
 * @swagger
 * /tasks:
 *   delete:
 *     tags:
 *       - Tasks
 *     summary: Eliminar una tarea
 *     description: Elimina una tarea específica del usuario autenticado
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/DeleteTaskRequest'
 *     responses:
 *       200:
 *         description: Tarea eliminada exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: boolean
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
taskRouter.delete("/", auth, async (req: AuthRequest, res) => {
  try {
    const { taskId }: { taskId: string } = req.body;
    await db.delete(tasks).where(eq(tasks.id, taskId));

    res.json(true);
  } catch (e) {
    res.status(500).json({ error: e });
  }
});

/**
 * @swagger
 * /tasks/sync:
 *   post:
 *     tags:
 *       - Tasks
 *     summary: Sincronizar múltiples tareas
 *     description: Sincroniza un lote de tareas desde el dispositivo local al servidor
 *     security:
 *       - BearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: array
 *             items:
 *               $ref: '#/components/schemas/Task'
 *     responses:
 *       201:
 *         description: Tareas sincronizadas exitosamente
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Task'
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
taskRouter.post("/sync", auth, async (req: AuthRequest, res) => {
  try {
    // req.body = { ...req.body, dueAt: new Date(req.body.dueAt), uid: req.user };
    const tasksList = req.body;

    const filteredTasks: NewTask[] = [];

    for (let t of tasksList) {
      t = {
        ...t,
        dueAt: new Date(t.dueAt),
        createdAt: new Date(t.createdAt),
        updatedAt: new Date(t.updatedAt),
        uid: req.user,
      };
      filteredTasks.push(t);
    }

    const pushedTasks = await db
      .insert(tasks)
      .values(filteredTasks)
      .returning();

    res.status(201).json(pushedTasks);
  } catch (e) {
    console.log(e);
    res.status(500).json({ error: e });
  }
});

export default taskRouter;
