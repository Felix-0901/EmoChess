-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('PLAYER', 'PARENT', 'THERAPIST');

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "displayName" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'PLAYER',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "game_records" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3),
    "initialEmotion" TEXT NOT NULL,
    "result" TEXT,
    "durationSeconds" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "game_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "move_records" (
    "id" TEXT NOT NULL,
    "gameRecordId" TEXT NOT NULL,
    "moveNumber" INTEGER NOT NULL,
    "san" TEXT NOT NULL,
    "player" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "preFen" TEXT,
    "postFen" TEXT,

    CONSTRAINT "move_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "chat_records" (
    "id" TEXT NOT NULL,
    "gameRecordId" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "sender" TEXT NOT NULL,
    "message" TEXT NOT NULL,
    "userChoice" TEXT,
    "aiResponse" TEXT,
    "moveNumber" INTEGER,
    "whitePreFen" TEXT,
    "whitePostFen" TEXT,
    "blackPostFen" TEXT,
    "roundId" TEXT,

    CONSTRAINT "chat_records_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "emotion_records" (
    "id" TEXT NOT NULL,
    "gameRecordId" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "emotion" TEXT NOT NULL,
    "moveNumber" INTEGER,
    "trigger" TEXT,

    CONSTRAINT "emotion_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "game_records_userId_sessionId_key" ON "game_records"("userId", "sessionId");

-- AddForeignKey
ALTER TABLE "game_records" ADD CONSTRAINT "game_records_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "move_records" ADD CONSTRAINT "move_records_gameRecordId_fkey" FOREIGN KEY ("gameRecordId") REFERENCES "game_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "chat_records" ADD CONSTRAINT "chat_records_gameRecordId_fkey" FOREIGN KEY ("gameRecordId") REFERENCES "game_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "emotion_records" ADD CONSTRAINT "emotion_records_gameRecordId_fkey" FOREIGN KEY ("gameRecordId") REFERENCES "game_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;
