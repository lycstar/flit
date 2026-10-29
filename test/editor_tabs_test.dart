import 'package:flutter_test/flutter_test.dart';
import 'package:flit/features/editor/file_kind.dart';
import 'package:flit/features/workspace/editor_tabs.dart';
import 'package:flit/features/workspace/project_documents.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProjectDocuments documents;
  late EditorTabs tabs;

  setUp(() {
    documents = ProjectDocuments(
      '/project',
      read: (_) async => 'text',
      write: (_, _) async => true,
    );
    tabs = EditorTabs(documents);
  });

  tearDown(() async {
    tabs.dispose();
    await documents.close();
  });

  Future<EditorDocument> open(String path) async {
    await documents.open(path);
    return documents.current!;
  }

  test('a document is shown once; closing walks to the neighbour', () async {
    final a = await open('lib/a.dart');
    final b = await open('lib/b.dart');
    tabs.showDocument(a);
    tabs.showDocument(b);
    tabs.showDocument(a);
    expect(tabs.items.length, 2);
    expect((tabs.current as CodeTab).document, same(a));

    tabs.showFile('assets/logo.png', FileKind.image);
    expect(
      tabs.items.map((item) => item.path),
      ['lib/a.dart', 'lib/b.dart', 'assets/logo.png'],
    );
    // 关掉当前的最后一项 → 左邻
    expect(tabs.close(tabs.current!)!.path, 'lib/b.dart');
    // 关掉当前的第一项 → 右邻
    tabs.select(tabs.items.first);
    tabs.close(tabs.current!);
    expect(tabs.current!.path, 'lib/b.dart');
    expect(tabs.items.length, 1);
    // 关掉非当前项不改变选中
    tabs.showFile('x.bin', FileKind.binary);
    tabs.select(tabs.items.first);
    tabs.close(tabs.items.last);
    expect(tabs.current!.path, 'lib/b.dart');
  });

  test('file cards dedupe by path, re-kind in place, documents insert at', () async {
    tabs.showFile('x.bin', FileKind.binary);
    tabs.showFile('x.bin', FileKind.binary);
    expect(tabs.items.length, 1);
    tabs.showFile('x.bin', FileKind.image);
    expect(tabs.items.length, 1);
    expect((tabs.current as FileTab).kind, FileKind.image);
    final c = await open('c.dart');
    tabs.showDocument(c, at: 0);
    expect(tabs.items.first.path, 'c.dart');
    expect(tabs.current!.path, 'c.dart');
  });

  test('buffers that vanish take their tab along; closeDocument releases', () async {
    final a = await open('lib/a.dart');
    final b = await open('lib/b.dart');
    tabs.showDocument(a);
    tabs.showDocument(b);
    tabs.select(tabs.items.first);
    await documents.deletePath('lib/a.dart', apply: () async {});
    expect(tabs.items.map((item) => item.path), ['lib/b.dart']);
    expect(tabs.current!.path, 'lib/b.dart');

    await documents.closeDocument(b);
    expect(documents.contains(b), isFalse);
    expect(tabs.isEmpty, isTrue);
    expect(tabs.current, isNull);
  });

  test('renamed documents keep their tab: identity, not path', () async {
    final a = await open('lib/a.dart');
    tabs.showDocument(a);
    await documents.renamePath('lib/a.dart', 'lib/z.dart', apply: () async {});
    expect(tabs.items.single.path, 'lib/z.dart');
    expect(tabs.current, same(tabs.items.single));
    expect(tabs.items.single.name, 'z.dart');
  });
}
