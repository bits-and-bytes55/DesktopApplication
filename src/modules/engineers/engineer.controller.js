const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

// ✅ POST Engineer
exports.createEngineer = async (req, res) => {
  try {
    const {
      firstName,
      lastName,
      cell,
      office,
      email,
      photoUrl,
    } = req.body;

    if (!firstName || !lastName) {
      return res.status(400).json({
        message: "First name and last name are required",
      });
    }

    const engineer = await prisma.engineer.create({
      data: {
        firstName,
        lastName,
        cell,
        office,
        email,
        photoUrl,
      },
    });

    res.status(201).json(engineer);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
};

// ✅ GET Engineers (for dropdown)
exports.getEngineers = async (req, res) => {
  try {
    const engineers = await prisma.engineer.findMany({
      orderBy: { createdAt: 'desc' },
    });

    res.json(engineers);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
