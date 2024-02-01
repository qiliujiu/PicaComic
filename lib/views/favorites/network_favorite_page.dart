import 'package:flutter/material.dart';
import 'package:pica_comic/comic_source/comic_source.dart';
import 'package:pica_comic/network/base_comic.dart';
import 'package:pica_comic/network/res.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/views/eh_views/eh_favourite_page.dart';
import 'package:pica_comic/views/main_page.dart';
import 'package:pica_comic/views/page_template/comics_page.dart';
import 'package:pica_comic/views/widgets/grid_view_delegate.dart';
import 'package:pica_comic/views/widgets/show_error.dart';

import '../../foundation/app.dart';
import '../widgets/show_message.dart';

class NetworkFavoritePage extends StatelessWidget {
  const NetworkFavoritePage(this.data, {super.key});

  final FavoriteData data;

  @override
  Widget build(BuildContext context) {
    if(data.key == "ehentai"){
      return const EhFavoritePage();
    }
    return data.multiFolder ?
      _MultiFolderFavoritesPage(data) :
      _NormalFavoritePage(data);
  }
}

class _NormalFavoritePage extends ComicsPage<BaseComic>{
  const _NormalFavoritePage(this.data);

  final FavoriteData data;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) {
    return data.loadComic(i);
  }

  @override
  String? get tag => "Network Comics Page: ${data.title}";

  @override
  String get title => data.title;

  ComicType _getType() => switch(data.key){
    "picacg" => ComicType.picacg,
    "ehentai" => ComicType.ehentai,
    "jm" => ComicType.jm,
    "htmanga" => ComicType.htManga,
    "nhentai" => ComicType.nhentai,
    _ => ComicType.other
  };

  @override
  ComicType get type => _getType();

  @override
  bool get withScaffold => false;

  @override
  bool get showTitle => false;

  @override
  bool get showBackWhenError => false;

}

class _MultiFolderFavoritesPage extends StatefulWidget {
  const _MultiFolderFavoritesPage(this.data);

  final FavoriteData data;

  @override
  State<_MultiFolderFavoritesPage> createState() => _MultiFolderFavoritesPageState();
}

class _MultiFolderFavoritesPageState extends State<_MultiFolderFavoritesPage> {
  bool _loading = true;

  String? _errorMessage;

  Map<String, String>? folders;

  void loadPage() async{
    var res = await widget.data.loadFolders!();
    _loading = false;
    if(res.error){
      setState(() {
        _errorMessage = res.errorMessage;
      });
    } else {
      setState(() {
        folders = res.data;
      });
    }
  }

  void openFolder(String key, String title){
    MainPage.to(() => _FavoriteFolder(widget.data, key, title));
  }

  @override
  Widget build(BuildContext context) {
    if(_loading){
      loadPage();
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if(_errorMessage != null){
      return showNetworkError(_errorMessage!, () => setState(() {
        _loading = true;
        _errorMessage = null;
      }), context, showBack: false);
    } else {
      var length = folders!.length;
      if(widget.data.allFavoritesId != null)  length++;
      final keys = folders!.keys.toList();

      return CustomScrollView(
        slivers: [
          SliverGridViewWithFixedItemHeight(
            delegate: SliverChildBuilderDelegate(
                childCount: length, (context, i) {
              if(widget.data.allFavoritesId != null){
                if(i == 0){
                  return _FolderTile(
                      name: "全部".tl,
                      onTap: () => openFolder(widget.data.allFavoritesId!, "全部".tl));
                } else {
                  i--;
                  return _FolderTile(
                    name: folders![keys[i]]!,
                    onTap: () => openFolder(keys[i], folders![keys[i]]!),
                    deleteFolder: widget.data.deleteFolder == null ? null :
                        () => widget.data.deleteFolder!(keys[i]),
                    updateState: () => setState(() {
                      _loading = true;
                    }),);
                }
              } else {
                return _FolderTile(
                  name: folders![keys[i]]!,
                  onTap: () => openFolder(keys[i], folders![keys[i]]!),
                  deleteFolder: widget.data.deleteFolder == null ? null :
                      () => widget.data.deleteFolder!(keys[i]),
                  updateState: () => setState(() {
                    _loading = true;
                  }),);
              }
            }),
            maxCrossAxisExtent: 450,
            itemHeight: 64,
          ),
          if(widget.data.addFolder != null)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: Center(
                  child: TextButton(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("创建收藏夹".tl),
                        const Icon(
                          Icons.add,
                          size: 18,
                        ),
                      ],
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return _CreateFolderDialog(widget.data, () => setState((){
                              _loading = true;
                            }));
                          });
                    },
                  ),
                ),
              ),
            )
        ],
      );
    }
  }
}


class _FolderTile extends StatelessWidget {
  const _FolderTile(
      {required this.name, required this.onTap, this.deleteFolder,
        this.updateState});

  final String name;

  final Future<Res<bool>> Function()? deleteFolder;

  final void Function()? updateState;

  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
          child: Row(
            children: [
              const SizedBox(width: 16,),
              Icon(
                Icons.folder,
                size: 35,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (deleteFolder != null)
                IconButton(
                  icon: const Icon(Icons.delete_forever_outlined),
                  onPressed: () => onDeleteFolder(context),
                )
              else
                const Icon(Icons.arrow_right),
              if (deleteFolder == null)
                const SizedBox(width: 8,)
            ],
          ),
        ),
      ),
    );
  }

  void onDeleteFolder(BuildContext context){
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("确认删除".tl),
            content: Text("要删除这个收藏夹吗".tl),
            actions: [
              TextButton(
                  onPressed: () => App.globalBack(),
                  child: const Text("取消")),
              TextButton(
                  onPressed: () async {
                    App.globalBack();
                    showMessage(context, "正在删除收藏夹".tl);
                    var res = await deleteFolder!();
                    showMessage(
                        App.globalContext,
                        res.error
                            ? res.errorMessage!
                            : "删除成功".tl);
                    if (!res.error) {
                      updateState?.call();
                    } else {
                      showMessage(
                          App.globalContext,
                          res.error
                              ? res.errorMessage!
                              : "删除失败".tl);
                    }
                  },
                  child: Text("确认".tl)),
            ],
          );
        });
  }
}

class _CreateFolderDialog extends StatefulWidget {
  const _CreateFolderDialog(this.data, this.updateState);

  final FavoriteData data;

  final void Function() updateState;

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  var controller = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text("创建收藏夹".tl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: "名称".tl,
            ),
          ),
        ),
        const SizedBox(
          width: 200,
          height: 10,
        ),
        if (loading)
          const SizedBox(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
        else
          SizedBox(
              height: 35,
              child: Center(
                child: TextButton(
                    onPressed: () {
                      setState(() {
                        loading = true;
                      });
                      widget.data.addFolder!(controller.text).then((b) {
                        if (b.error) {
                          showMessage(context, b.errorMessage!);
                          setState(() {
                            loading = false;
                          });
                        } else {
                          App.globalBack();
                          showMessage(context, "成功创建".tl);
                          widget.updateState();
                        }
                      });
                    },
                    child: Text("提交".tl)),
              ))
      ],
    );
  }
}

class _FavoriteFolder extends ComicsPage<BaseComic>{
  const _FavoriteFolder(this.data, this.folderID, this.title);

  final FavoriteData data;

  final String folderID;

  @override
  final String title;

  @override
  Future<Res<List<BaseComic>>> getComics(int i) {
    return data.loadComic(i, folderID);
  }

  @override
  String? get tag => "Favorites Folder $folderID";

  ComicType _getType() => switch(data.key){
    "picacg" => ComicType.picacg,
    "ehentai" => ComicType.ehentai,
    "jm" => ComicType.jm,
    "htmanga" => ComicType.htManga,
    "nhentai" => ComicType.nhentai,
    _ => ComicType.other
  };

  @override
  ComicType get type => _getType();

  @override
  bool get withScaffold => true;

  @override
  bool get showTitle => true;
}