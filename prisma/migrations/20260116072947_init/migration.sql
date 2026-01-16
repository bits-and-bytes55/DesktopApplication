-- CreateTable
CREATE TABLE "Engineer" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "cell" TEXT,
    "office" TEXT,
    "email" TEXT,
    "photoUrl" TEXT,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "Report" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "reportNo" INTEGER NOT NULL,
    "wellName" TEXT NOT NULL,
    "engineerId" INTEGER,
    "engineer2Id" INTEGER,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Report_engineerId_fkey" FOREIGN KEY ("engineerId") REFERENCES "Engineer" ("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Report_engineer2Id_fkey" FOREIGN KEY ("engineer2Id") REFERENCES "Engineer" ("id") ON DELETE SET NULL ON UPDATE CASCADE
);
