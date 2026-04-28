import { z } from "zod";

export const emailSchema = z.string().trim().email({ message: "Invalid email" }).max(255);
export const passwordSchema = z
  .string()
  .min(8, { message: "At least 8 characters" })
  .max(72, { message: "Too long" });
export const displayNameSchema = z
  .string()
  .trim()
  .min(1, { message: "Required" })
  .max(60, { message: "Too long" });

export const signInSchema = z.object({ email: emailSchema, password: passwordSchema });
export const signUpSchema = z.object({
  email: emailSchema,
  password: passwordSchema,
  displayName: displayNameSchema,
});
export const messageSchema = z.string().trim().min(1).max(4000);
