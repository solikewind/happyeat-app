import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/widgets/menu_cover_image.dart';

class MenuEditPage extends ConsumerStatefulWidget {
  const MenuEditPage({super.key, this.menuId});

  final String? menuId;

  bool get isEditing => menuId != null && menuId!.isNotEmpty;

  @override
  ConsumerState<MenuEditPage> createState() => _MenuEditPageState();
}

class _MenuEditPageState extends ConsumerState<MenuEditPage> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  List<MenuCategory> _categories = [];
  String? _categoryId;
  String? _imageUrl;
  String? _objectId;
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  MenuItem get _previewMenu => MenuItem(
    id: widget.menuId ?? '0',
    name: _nameCtrl.text.trim().isEmpty ? '菜品名称' : _nameCtrl.text.trim(),
    priceYuan: double.tryParse(_priceCtrl.text.trim()) ?? 0,
    categoryId: _categoryId ?? '',
    description: _descCtrl.text.trim(),
    image: _imageUrl,
    objectId: _objectId,
  );

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(menuRepositoryProvider);
      final categories = await repo.listCategories();
      MenuItem? existing;
      if (widget.isEditing) {
        existing = await repo.getMenu(widget.menuId!);
      }
      if (!mounted) return;
      setState(() {
        _categories = categories;
        if (existing != null) {
          _nameCtrl.text = existing.name;
          _priceCtrl.text = existing.priceYuan.toStringAsFixed(
            existing.priceYuan.truncateToDouble() == existing.priceYuan ? 0 : 2,
          );
          _descCtrl.text = existing.description ?? '';
          _categoryId = existing.categoryId;
          _imageUrl = existing.image;
          _objectId = existing.objectId;
        } else if (categories.isNotEmpty) {
          _categoryId = categories.first.id;
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final object = await ref
          .read(menuRepositoryProvider)
          .uploadObject(file.path, fileName: file.name);
      if (!mounted) return;
      setState(() {
        _objectId = object.id;
        _imageUrl = object.url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('图片上传成功')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final categoryId = _categoryId;
    if (name.isEmpty) {
      _showError('请填写菜品名称');
      return;
    }
    if (price == null || price < 0) {
      _showError('请填写正确价格');
      return;
    }
    if (categoryId == null || categoryId.isEmpty) {
      _showError('请选择分类');
      return;
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(menuRepositoryProvider);
      final description = _descCtrl.text.trim();
      if (widget.isEditing) {
        await repo.updateMenu(
          id: widget.menuId!,
          name: name,
          priceYuan: price,
          categoryId: categoryId,
          description: description,
          image: _imageUrl,
          objectId: _objectId,
        );
      } else {
        await repo.createMenu(
          name: name,
          priceYuan: price,
          categoryId: categoryId,
          description: description.isEmpty ? null : description,
          image: _imageUrl,
          objectId: _objectId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? '已保存修改' : '已添加菜品')),
      );
      context.pop(true);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (!widget.isEditing) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除菜品'),
        content: Text('确定删除「${_nameCtrl.text.trim()}」？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(menuRepositoryProvider).deleteMenu(widget.menuId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('菜品已删除')),
      );
      context.pop(true);
    } on ApiException catch (e) {
      _showError(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑菜品' : '添加菜品'),
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      MenuCoverImage(
                        menu: _previewMenu,
                        size: 120,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _uploading ? null : _pickImage,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: _uploading
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.photo_camera_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '点击相机图标上传封面',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '菜品名称',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    labelText: '价格（元）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoryId,
                  decoration: const InputDecoration(
                    labelText: '分类',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _categoryId = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: '描述（可选）',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(widget.isEditing ? '保存修改' : '确认添加'),
                ),
              ],
            ),
    );
  }
}
