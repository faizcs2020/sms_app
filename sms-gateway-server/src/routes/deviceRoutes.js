const express = require('express');
const router = express.Router();
const deviceController = require('../controllers/deviceController');
const { protect } = require('../middleware/authMiddleware');

router.post('/heartbeat', protect, deviceController.heartbeat);
router.get('/', protect, deviceController.getDevices);
router.post('/', protect, deviceController.registerDevice);

module.exports = router;
