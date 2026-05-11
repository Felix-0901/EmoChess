-- CreateEnum
CREATE TYPE "TitleRarity" AS ENUM ('COMMON', 'RARE', 'EPIC');

-- CreateTable
CREATE TABLE "titles" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "nameZh" TEXT NOT NULL,
    "descriptionEn" TEXT NOT NULL,
    "descriptionZh" TEXT NOT NULL,
    "rarity" "TitleRarity" NOT NULL DEFAULT 'COMMON',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "titles_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_titles" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "titleId" TEXT NOT NULL,
    "unlockedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "equipped" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "user_titles_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "titles_key_key" ON "titles"("key");

-- CreateIndex
CREATE UNIQUE INDEX "user_titles_userId_titleId_key" ON "user_titles"("userId", "titleId");

-- AddForeignKey
ALTER TABLE "user_titles" ADD CONSTRAINT "user_titles_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_titles" ADD CONSTRAINT "user_titles_titleId_fkey" FOREIGN KEY ("titleId") REFERENCES "titles"("id") ON DELETE CASCADE ON UPDATE CASCADE;
