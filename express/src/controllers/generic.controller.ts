import express from "express";

export function successOk(req: express.Request, res: express.Response, result: any, message: string = "Thành công!") {
  return res.status(200).json({ status: true, message, result });
}

export function successCreated(req: express.Request, res: express.Response, result: any, message: string = "Đã tạo thành công!") {
  return res.status(201).json({ status: true, message, result });
}

export function badRequest(req: express.Request, res: express.Response, error: any, message: string = "Yêu cầu không hợp lệ!") {
  return res.status(400).json({ status: false, message, error });
}

export function unauthorized(req: express.Request, res: express.Response, error: any, message: string = "Không có quyền truy cập!") {
  return res.status(401).json({ status: false, message, error });
}

export function forbidden(req: express.Request, res: express.Response, error: any, message: string = "Bị cấm truy cập!") {
  return res.status(403).json({ status: false, message, error });
}

export function pageNotFound(req: express.Request, res: express.Response, message: string = "Trang không tồn tại!") {
  return res.status(404).json({ status: false, message });
}

export function tooManyRequest(req: express.Request, res: express.Response, message: string = "Bạn đã thao tác quá nhanh, hãy thử lại sau!") {
  return res.status(429).json({ status: false, message });
}

export function internalServerError(req: express.Request, res: express.Response, error: any, message: string = "Lỗi hệ thống!") {
  return res.status(500).json({ status: false, message, error });
}