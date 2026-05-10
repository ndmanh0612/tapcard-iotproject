import express from 'express';
import * as genericRes from "./generic.controller";
import crypto from 'crypto';

import attendanceModel from "../models/attendance.model";
import readerModel from "../models/reader.model";
import tagModel from "../models/tag.model";
import trackModel from "../models/track.model";
import mongoose from 'mongoose';
import { io } from '../index';

export async function getEntity(req: express.Request, res: express.Response) {
  try {
    const queryId = req.query.id?.toString().trim();
    const queryDate = req.query.date?.toString().trim();
    const queryTimeIn = parseInt(req.query.timeIn?.toString().trim() || "0", 10);
    const queryTimeOut = parseInt(req.query.timeOut?.toString().trim() || "0", 10);
    const queryReader = req.query.reader?.toString().trim();
    const queryStudent = req.query.student?.toString().trim();
    const queryReason = req.query.reason?.toString().trim();
    let query = {};
    if (queryId) query = { ...query, _id: queryId };
    if (queryDate) query = { ...query, date: queryDate };
    if (queryTimeIn) query = { ...query, timeIn: { $gte: queryTimeIn } };
    if (queryTimeOut) query = { ...query, timeOut: { $lte: queryTimeOut } };
    if (queryReader) query = { ...query, reader: queryReader };
    if (queryStudent) query = { ...query, students: queryStudent };
    if (queryReason) query = { ...query, reason: queryReason };

    // Get all attendance records
    const allAttendance = await attendanceModel.find(query).sort("date").populate("students", "-password -__v -createdAt -updatedAt").populate("reader", "-password -__v -createdAt -updatedAt");
    if (!allAttendance) return genericRes.badRequest(req, res, "Failed to get attendance records!");
    return genericRes.successOk(req, res, allAttendance, `Here are ${allAttendance.length} attendance records.`);
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message, "Something went wrong!");
  }
}

export async function createEntity(req: express.Request, res: express.Response) {
  try {
    // Ensure requirements
    let date = new Date().toISOString().split("T")[0];
    let reader = req.body.reader?.toString().trim();
    let studentsEncryptedRFIDs = req.body.students;
    let reason = req.body.reason?.toString().trim().toLowerCase();
    let isOut = req.body.isOut || false;
    let notes = req.body.notes?.toString().trim() || "";
    if (!reader) return genericRes.badRequest(req, res, "Invalid reader.");
    if (!studentsEncryptedRFIDs || studentsEncryptedRFIDs.length == 0) return genericRes.badRequest(req, res, "Must provide at least one student.");
    if (!reason) return genericRes.badRequest(req, res, "Invalid reason.");

    // Get secret key from reader
    const readerData = await readerModel.findById(reader);
    if (!readerData) return genericRes.badRequest(req, res, "Invalid reader.");
    const base64Key = readerData.secret;
    if (!base64Key) return genericRes.badRequest(req, res, "Invalid reader secret key.");
    const secretKey = Buffer.from(base64Key, 'base64');

    // Decrypt student RFIDs
    console.log("studentsEncryptedRFIDs:", studentsEncryptedRFIDs);
    console.log("base64Key:", base64Key);
    console.log("secretKey:", secretKey);
    const decryptedRFIDs: string[] = [];
    for (const base64Cipher of studentsEncryptedRFIDs) {
      try {
        const encryptedData = Buffer.from(base64Cipher, 'base64');
        const decipher = crypto.createDecipheriv('aes-256-ecb', secretKey, null);
        decipher.setAutoPadding(false);
        const decrypted = Buffer.concat([
          decipher.update(encryptedData),
          decipher.final()
        ]);
        const decryptedText = decrypted.toString('utf8').replace(/[^\x20-\x7E]+/g, '');
        console.log("Decrypted buffer (hex):", decryptedText);
        decryptedRFIDs.push(decryptedText);
      } catch (err) {
        console.error('Failed to decrypt RFID:', err);
        decryptedRFIDs.push('[DECRYPTION_FAILED]');
      }
    }
    console.log("decryptedRFIDs:", decryptedRFIDs);

    // Retrieve student data from decrypted RFIDs from tag model
    const tags = await tagModel.find({ tag: { $in: decryptedRFIDs } });
    if (!tags) return genericRes.badRequest(req, res, "Failed to get student data!");
    const students = tags.map(tag => tag.associated._id);
    if (!students || students.length == 0) return genericRes.badRequest(req, res, "Failed to get student data!");
    console.log("students: ", students);

    // Log into track model
    const track = await trackModel.create({ students, tags: decryptedRFIDs });
    if (!track) return genericRes.badRequest(req, res, "Failed to log into track model!");

    // Check if attendance record already exists for the date, if yes append the students to the existing record
    const existingAttendance = await attendanceModel.findOne({ date, reader, isOut });
    if (existingAttendance) {
      const existingIds = existingAttendance.students.map(id => id.toString());
      const incomingIds = students.map(id => id.toString());
      const uniqueIds = [...new Set([...existingIds, ...incomingIds])];
      existingAttendance.students = uniqueIds.map(id => new mongoose.Types.ObjectId(id));
      existingAttendance.reason = reason;
      existingAttendance.notes = notes;
      await existingAttendance.save();
      return genericRes.successOk(req, res, existingAttendance, "Updated attendance record successfully!");
    }

    // Create attendance record
    const newAttendance = await attendanceModel.create({ date, reader, students, reason, isOut, notes, timeIn: isOut ? undefined : Date.now(), timeOut: isOut ? Date.now() : undefined, });
    if (!newAttendance) throw Error("Failed to create new attendance record!");

    return genericRes.successOk(req, res, newAttendance, "Added attendance record successfully!");
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message, "Something went wrong!");
  }
}

export async function startSession(req: express.Request, res: express.Response) {
  try {
    const reader = req.body.reader?.toString().trim();
    const reason = req.body.reason?.toString().trim().toLowerCase();
    const isOut = req.body.isOut || false;
    const date = new Date().toISOString().split("T")[0];

    if (!reader || !reason) return genericRes.badRequest(req, res, "Missing reader or reason.");

    // Close any existing open sessions for this reader today
    await attendanceModel.updateMany({ reader, date, isOpen: true }, { isOpen: false });

    const newSession = await attendanceModel.create({
      date,
      reader,
      reason,
      isOut,
      isOpen: true,
      students: [],
      timeIn: isOut ? undefined : Date.now(),
      timeOut: isOut ? Date.now() : undefined,
    });

    return genericRes.successCreated(req, res, newSession, "Phiên điểm danh đã được bắt đầu!");
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message);
  }
}

export async function endSession(req: express.Request, res: express.Response) {
  try {
    const sessionId = req.body.id?.toString().trim();
    if (!sessionId) return genericRes.badRequest(req, res, "Missing session ID.");

    const session = await attendanceModel.findByIdAndUpdate(sessionId, { isOpen: false }, { new: true });
    if (!session) return genericRes.badRequest(req, res, "Session not found.");

    return genericRes.successOk(req, res, session, "Phiên điểm danh đã kết thúc!");
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message);
  }
}

export async function swipeTag(req: express.Request, res: express.Response) {
  console.log("-----------------------------------------");
  console.log("[Swipe] Incoming request from ESP32...");
  try {
    const readerId = req.body.reader?.toString().trim();
    const encryptedTag = req.body.tag?.toString().trim();
    if (!readerId || !encryptedTag) {
      console.log("[Swipe] Missing readerId or tag in body");
      return genericRes.badRequest(req, res, "Missing reader or tag.");
    }

    const reader = await readerModel.findById(readerId);
    if (!reader) {
      console.log(`[Swipe] Reader not found: ${readerId}`);
      return genericRes.badRequest(req, res, "Máy quét không tồn tại.");
    }
    
    const secretKey = Buffer.from(reader.secret, 'base64');
    const encryptedData = Buffer.from(encryptedTag, 'base64');
    
    // Sử dụng CBC với IV là 0 để khớp với ESP32
    const iv = Buffer.alloc(16, 0);
    const decipher = crypto.createDecipheriv('aes-256-cbc', secretKey, iv);
    decipher.setAutoPadding(false);
    const decrypted = Buffer.concat([decipher.update(encryptedData), decipher.final()]);
    const tagUid = decrypted.toString('utf8').replace(/[^\x20-\x7E]+/g, '');
    
    console.log(`[Swipe] Reader: ${reader.name}, Tag UID: ${tagUid}, BindingMode: ${reader.isBindingMode}`);

    const tag = await tagModel.findOne({ tag: tagUid });
    if (!tag) {
      console.log(`[Swipe] Unregistered tag: ${tagUid}`);
      // Chỉ cho phép quẹt thẻ mới nếu Reader đang ở chế độ Gán thẻ (isBindingMode)
      if (reader.isBindingMode) {
        console.log(`[Swipe] Emitting tag-detected for ${tagUid}`);
        io.emit("tag-detected", { tag: tagUid, reader: readerId });
        return genericRes.successOk(req, res, {}, "Phát hiện thẻ mới trong chế độ Gán thẻ."); // Trả về success để ESP32 không báo lỗi
      }
      return genericRes.badRequest(req, res, "Thẻ chưa đăng ký và Chế độ Gán thẻ đang TẮT.");
    }

    const session = await attendanceModel.findOne({ reader: readerId, isOpen: true });
    if (!session && !reader.isBindingMode) {
      return genericRes.badRequest(req, res, "Không có phiên điểm danh nào đang mở.");
    }

    // Nếu có phiên đang mở, tiến hành ghi nhận điểm danh
    if (session) {
      if (!session.students.includes(tag.associated)) {
        session.students.push(tag.associated);
        await session.save();
      }

      // Gửi thông báo real-time cho App (Kèm theo thông tin User)
      const studentInfo = await mongoose.model("user").findById(tag.associated).select("name type mobileNo");

      io.emit("new-attendance", {
        student: studentInfo,
        tag: tagUid,
        reader: readerId,
        time: Date.now()
      });
      
      return genericRes.successOk(req, res, session, `Attendance logged for tag ${tagUid}`);
    }

    // Nếu không có phiên nhưng đang ở chế độ Binding, chỉ thông báo thành công cho ESP32 biết
    return genericRes.successOk(req, res, {}, `Tag ${tagUid} detected in Binding Mode (No session).`);
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message);
  }
}

export async function updateEntity(req: express.Request, res: express.Response) {
  try {
    return genericRes.internalServerError(req, res, "Not implemented yet!");
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message, "Something went wrong!");
  }
}

export async function deleteEntity(req: express.Request, res: express.Response) {
  try {
    return genericRes.internalServerError(req, res, "Not implemented yet!");
  } catch (error) {
    return genericRes.badRequest(req, res, (error as Error).message, "Something went wrong!");
  }
}