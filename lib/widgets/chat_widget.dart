import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../models/chat_message_model.dart';
import '../services/realtime_communication_service.dart';

class ChatWidget extends StatefulWidget {
  final String? orderId;
  final bool showMerchantChat;
  final bool showCustomerChat;

  const ChatWidget({
    super.key,
    this.orderId,
    this.showMerchantChat = true,
    this.showCustomerChat = true,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // Calculate number of tabs
    int tabCount = 0;
    if (widget.showMerchantChat) tabCount++;
    if (widget.showCustomerChat) tabCount++;
    
    _tabController = TabController(length: tabCount, vsync: this);
    
    // Listen for new messages to auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<RealtimeCommunicationService>(context, listen: false);
      service.onNewMessage = (message) {
        _scrollToBottom();
      };
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeCommunicationService>(
      builder: (context, service, child) {
        if (!service.isInitialized || !service.isConnected) {
          return _buildDisconnectedState();
        }

        final messages = service.chatMessages
            .where((msg) => widget.orderId == null || msg.orderId == widget.orderId)
            .toList();

        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(messages),
                ),
              ),
              _buildMessageInput(service),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.chat,
            color: AppColors.white,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text(
            'الرسائل',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'متصل',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    List<Tab> tabs = [];
    
    if (widget.showMerchantChat) {
      tabs.add(const Tab(
        icon: Icon(Icons.store),
        text: 'المطعم',
      ));
    }
    
    if (widget.showCustomerChat) {
      tabs.add(const Tab(
        icon: Icon(Icons.person),
        text: 'العميل',
      ));
    }

    if (tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.grey200, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: tabs,
      ),
    );
  }

  List<Widget> _buildTabViews(List<ChatMessage> messages) {
    List<Widget> tabViews = [];
    
    if (widget.showMerchantChat) {
      final merchantMessages = messages
          .where((msg) => msg.type == ChatMessageType.toMerchant || 
                        msg.type == ChatMessageType.fromMerchant)
          .toList();
      tabViews.add(_buildMessagesList(merchantMessages, ChatMessageType.toMerchant));
    }
    
    if (widget.showCustomerChat) {
      final customerMessages = messages
          .where((msg) => msg.type == ChatMessageType.toCustomer || 
                        msg.type == ChatMessageType.fromCustomer)
          .toList();
      tabViews.add(_buildMessagesList(customerMessages, ChatMessageType.toCustomer));
    }

    return tabViews;
  }

  Widget _buildMessagesList(List<ChatMessage> messages, ChatMessageType sendType) {
    if (messages.isEmpty) {
      return _buildEmptyState(sendType);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isOutgoing = message.type == sendType;
        
        return _buildMessageBubble(message, isOutgoing);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isOutgoing) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOutgoing) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                message.senderName.isNotEmpty ? message.senderName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOutgoing ? AppColors.primary : AppColors.grey100,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isOutgoing ? AppColors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isOutgoing 
                          ? AppColors.white.withValues(alpha: 0.7)
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isOutgoing) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.success,
              child: const Icon(
                Icons.delivery_dining,
                color: AppColors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput(RealtimeCommunicationService service) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.grey200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'اكتب رسالة...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.grey300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(service),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _sendMessage(service),
              icon: const Icon(
                Icons.send,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ChatMessageType type) {
    final recipientName = type == ChatMessageType.toMerchant ? 'المطعم' : 'العميل';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == ChatMessageType.toMerchant ? Icons.store : Icons.person,
            size: 64,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد رسائل مع $recipientName',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'ابدأ محادثة جديدة',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: AppColors.grey400,
            ),
            SizedBox(height: 16),
            Text(
              'غير متصل',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'يرجى التحقق من الاتصال بالإنترنت',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(RealtimeCommunicationService service) async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (widget.orderId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن إرسال رسالة بدون طلب نشط.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    try {
      // Determine recipient based on current tab
      final currentTabIndex = _tabController.index;
      bool isMerchantTab = widget.showMerchantChat && currentTabIndex == 0;
      
      if (!widget.showMerchantChat && widget.showCustomerChat) {
        isMerchantTab = false;
      }

      if (isMerchantTab) {
        await service.sendMessageToMerchant(widget.orderId!, message);
      } else {
        await service.sendMessageToCustomer(widget.orderId!, message);
      }

      // Clear input and scroll to bottom
      _messageController.clear();
      _scrollToBottom();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في إرسال الرسالة: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} د';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} س';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
