const express = require('express');
const router = express.Router();
const smsMobileController = require('../controllers/smsMobileController');
const { protect } = require('../middleware/authMiddleware');

router.post('/mobile', protect, smsMobileController.receiveMobileSms);
router.get('/mobile', protect, smsMobileController.getMobileSmsList);

module.exports = router;
