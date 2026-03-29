-- CreateTable
CREATE TABLE "ai_reports" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "gameRecordId" TEXT NOT NULL,
    "language" TEXT NOT NULL,
    "reportJson" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ai_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ai_reports_userId_gameRecordId_language_key" ON "ai_reports"("userId", "gameRecordId", "language");

-- AddForeignKey
ALTER TABLE "ai_reports" ADD CONSTRAINT "ai_reports_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ai_reports" ADD CONSTRAINT "ai_reports_gameRecordId_fkey" FOREIGN KEY ("gameRecordId") REFERENCES "game_records"("id") ON DELETE CASCADE ON UPDATE CASCADE;
