class AccountNode {
  final String id;
  final String name;
  final bool selectable;
  final List<AccountNode> children;

  AccountNode({
    required this.id,
    required this.name,
    this.selectable = true,
    this.children = const [],
  });
}
