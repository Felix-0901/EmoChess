-- CreateTable
CREATE TABLE "conversation_round_records" (
    "id" TEXT NOT NULL,
    "gameRecordId" TEXT NOT NULL,
    "roundId" TEXT NOT NULL,
    "timestamp" TIMESTAMP(3) NOT NULL,
    "moveNumber" INTEGER,
    "emotion" TEXT,
    "trigger" TEXT,
    "intent" TEXT,
    "angleKey" TEXT,
    "promptVersion" INTEGER,
    "aiQuestion" TEXT NOT NULL,
    "choices" JSONB NOT NULL,
    "selectedChoice" TEXT NOT NULL,
    "aiReply" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversation_round_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "conversation_round_records_gameRecordId_roundId_key" ON "conversation_round_records"("gameRecordId", "roundId");

-- AddForeignKey
ALTER TABLE "conversation_round_records" ADD CONSTRAINT "conversation_round_records_gameRecordId_fkey" FOREIGN KEY ("gameRecordId") REFERENCES "game_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;
