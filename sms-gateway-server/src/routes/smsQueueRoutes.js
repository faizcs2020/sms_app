const express = require('express');
const router = express.Router();
const smsQueueController = require('../controllers/smsQueueController');
const { protect } = require('../middleware/authMiddleware');

router.post('/', protect, smsQueueController.createQueueItem);
router.get('/', protect, smsQueueController.getPendingQueue);
router.post('/:id/sent', protect, smsQueueController.markSent);
router.post('/:id/failed', protect, smsQueueController.markFailed);
router.get('/:id', protect, smsQueueController.getQueueItemById);

module.exports = router;
