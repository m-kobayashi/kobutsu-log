import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:kobutsu_log/models/transaction.dart';
import 'package:kobutsu_log/providers/auth_provider.dart';
import 'package:kobutsu_log/providers/transaction_provider.dart';
import 'package:kobutsu_log/config/constants.dart';
import 'package:kobutsu_log/utils/validators.dart';
import 'package:kobutsu_log/utils/formatters.dart';
import 'package:kobutsu_log/widgets/loading_overlay.dart';
import 'package:flutter/foundation.dart' show kIsWeb, Uint8List;
import 'dart:io' if (dart.library.html) 'dart:html' as platform;

/// 取引登録・編集画面
class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;

  const TransactionFormScreen({
    super.key,
    this.transactionId,
  });

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _counterpartyNameController = TextEditingController();
  final _counterpartyAddressController = TextEditingController();
  final _counterpartyAgeController = TextEditingController();
  final _counterpartyOccupationController = TextEditingController();
  final _notesController = TextEditingController();

  String _transactionType = AppConstants.transactionTypeBuy;
  String? _itemCategory;
  DateTime _transactionDate = DateTime.now();
  String _idVerificationType = 'drivers_license';
  XFile? _imageFile;
  String? _photoUrl;
  bool _isLoading = false;
  bool _isEditing = false;
  Transaction? _originalTransaction;

  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _isEditing = true;
      _loadTransaction();
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _counterpartyNameController.dispose();
    _counterpartyAddressController.dispose();
    _counterpartyAgeController.dispose();
    _counterpartyOccupationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadTransaction() {
    // ローカルストレージから取引を読み込み
    final localStorage = ref.read(localStorageServiceProvider);
    final transaction = localStorage.getTransaction(widget.transactionId!);

    if (transaction != null) {
      setState(() {
        _originalTransaction = transaction;
        _transactionType = transaction.transactionType;
        _itemNameController.text = transaction.itemName;
        _itemCategory = transaction.itemCategory;
        _quantityController.text = transaction.quantity.toString();
        _priceController.text = transaction.price.toString();
        _transactionDate = transaction.transactionDate;
        _counterpartyNameController.text = transaction.counterpartyName;
        _counterpartyAddressController.text = transaction.counterpartyAddress;
        _counterpartyAgeController.text = transaction.counterpartyAge?.toString() ?? '';
        _counterpartyOccupationController.text = transaction.counterpartyOccupation ?? '';
        _idVerificationType = transaction.idVerificationType;
        _photoUrl = transaction.photoUrl;
        _notesController.text = transaction.notes ?? '';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_transactionDate),
      );

      if (time != null) {
        setState(() {
          _transactionDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id ?? '';

      // 画像アップロード（新規画像がある場合）
      String? photoUrl = _photoUrl;
      if (_imageFile != null) {
        final apiService = ref.read(apiServiceProvider);
        photoUrl = await apiService.uploadImage(_imageFile!.path);
      }

      // 取引データ作成
      final transaction = Transaction(
        id: _isEditing ? _originalTransaction!.id : const Uuid().v4(),
        userId: userId,
        transactionType: _transactionType,
        itemName: _itemNameController.text.trim(),
        itemCategory: _itemCategory,
        quantity: int.parse(_quantityController.text),
        price: int.parse(_priceController.text),
        transactionDate: _transactionDate,
        counterpartyName: _counterpartyNameController.text.trim(),
        counterpartyAddress: _counterpartyAddressController.text.trim(),
        counterpartyAge: _counterpartyAgeController.text.isEmpty
            ? null
            : int.tryParse(_counterpartyAgeController.text),
        counterpartyOccupation: _counterpartyOccupationController.text.isEmpty
            ? null
            : _counterpartyOccupationController.text.trim(),
        idVerificationType: _idVerificationType,
        photoUrl: photoUrl,
        notes: _notesController.text.isEmpty ? null : _notesController.text.trim(),
        createdAt: _isEditing ? _originalTransaction!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 保存
      if (_isEditing) {
        await ref.read(transactionListProvider.notifier).updateTransaction(transaction);
      } else {
        await ref.read(transactionListProvider.notifier).createTransaction(transaction);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '取引を更新しました' : '取引を登録しました'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除確認'),
        content: const Text('この取引を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);

      try {
        await ref.read(transactionListProvider.notifier).deleteTransaction(widget.transactionId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('取引を削除しました'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '取引編集' : '新規登録'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _handleDelete,
                ),
              ]
            : null,
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _isEditing ? '更新中...' : '登録中...',
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 取引区分
              DropdownButtonFormField<String>(
                value: _transactionType,
                decoration: const InputDecoration(
                  labelText: '取引区分',
                ),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.transactionTypeBuy,
                    child: const Text('買取'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.transactionTypeSell,
                    child: const Text('販売'),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _transactionType = value!);
                },
              ),
              const SizedBox(height: 16),

              // 品名
              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: '品名 *',
                ),
                validator: (value) => Validators.required(value, fieldName: '品名'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // カテゴリ
              DropdownButtonFormField<String>(
                value: _itemCategory,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                ),
                items: AppConstants.itemCategories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(Formatters.itemCategory(category)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _itemCategory = value);
                },
              ),
              const SizedBox(height: 16),

              // 数量と金額
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: '数量',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.positiveNumber(value, fieldName: '数量'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: '金額（円） *',
                        suffixText: '円',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) => Validators.positiveNumber(value, fieldName: '金額'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 取引日時
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('取引日時 *'),
                subtitle: Text(Formatters.dateTime(_transactionDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              const Divider(),
              const SizedBox(height: 16),

              // セクションタイトル: 相手方情報
              Text(
                '相手方情報',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 氏名
              TextFormField(
                controller: _counterpartyNameController,
                decoration: const InputDecoration(
                  labelText: '氏名 *',
                ),
                validator: (value) => Validators.required(value, fieldName: '氏名'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // 住所
              TextFormField(
                controller: _counterpartyAddressController,
                decoration: const InputDecoration(
                  labelText: '住所 *',
                ),
                validator: (value) => Validators.required(value, fieldName: '住所'),
                textInputAction: TextInputAction.next,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // 年齢と職業
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _counterpartyAgeController,
                      decoration: const InputDecoration(
                        labelText: '年齢',
                        suffixText: '歳',
                      ),
                      keyboardType: TextInputType.number,
                      validator: Validators.age,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _counterpartyOccupationController,
                      decoration: const InputDecoration(
                        labelText: '職業',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 本人確認方法
              DropdownButtonFormField<String>(
                value: _idVerificationType,
                decoration: const InputDecoration(
                  labelText: '本人確認方法 *',
                ),
                items: AppConstants.idVerificationTypes.entries.map((entry) {
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _idVerificationType = value!);
                },
              ),
              const SizedBox(height: 24),

              // 写真
              Text(
                '写真',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_imageFile != null || _photoUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _imageFile != null
                          ? FutureBuilder<Uint8List>(
                              future: _imageFile!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const SizedBox(
                                  height: 200,
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              },
                            )
                          : Image.network(
                              _photoUrl!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _imageFile = null;
                            _photoUrl = null;
                          });
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.5),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('撮影'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('選択'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // メモ
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // 登録ボタン
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: Text(_isEditing ? '更新する' : '登録する'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
