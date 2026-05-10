import express from "express";
import cors from 'cors';
import compression from 'compression';

import * as genericRes from "./controllers/generic.controller";
import connectDB from "./configurations/db.config";
import env from "./configurations/env.config";
import authRouter from "./routes/auth.router";
import userRouter from "./routes/user.router";
import readerRouter from "./routes/reader.router";
import tagRouter from "./routes/tag.router";
import attendanceRouter from "./routes/attendance.router";
import { createServer } from "http";
import { Server } from "socket.io";

// Express app
const app = express();
const server = createServer(app);
export const io = new Server(server, {
  cors: { origin: "*" }
});

io.on("connection", (socket) => {
  console.log(`[socket] New connection: ${socket.id}`);
  socket.on("disconnect", () => console.log(`[socket] Disconnected: ${socket.id}`));
});

// Middlewares
app.use(cors());
app.use(compression());
app.use(express.json());

// Routes
app.get("/", (_, res: any) => res.status(200).json({ msg: `Máy chủ đang hoạt động ở chế độ ${env.ENV}!` }));
app.use("/auth", authRouter);
app.use("/user", userRouter);
app.use("/reader", readerRouter);
app.use("/tag", tagRouter);
app.use("/attendance", attendanceRouter);
app.all("*", (req, res) => genericRes.pageNotFound(req, res));

// Driver function
async function main() {
  await connectDB();
  server.listen(
    env.PORT,
    () => console.info(`[success] Done! ${env.ENV} environment at port "${env.PORT}".`),
  );
}

// Start the server
main();