import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kawalcovid19/blocs/posts/bloc.dart';
import 'package:kawalcovid19/common/navigation.dart';
import 'package:kawalcovid19/common/screen_arguments.dart';
import 'package:kawalcovid19/common/sizes.dart';
import 'package:kawalcovid19/network/api/rest_client.dart';
import 'package:kawalcovid19/ui/home/detail_article.dart';
import 'package:kawalcovid19/widget/card/card_article.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Completer<void> _refreshCompleter;
  int currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _refreshCompleter = Completer<void>();
    BlocProvider.of<PostsBloc>(context).listen((state) {
      if (state is PostsLoaded || state is PostsNotLoaded) {
        if (state is PostsLoaded && state.page > 1) {
          setState(() {
            currentPage++;
          });
        } else {
          _refreshCompleter?.complete();
          _refreshCompleter = Completer();
        }
      }
    });
  }

  Future<void> _refresh() {
    BlocProvider.of<PostsBloc>(context).add(LoadPosts());

    return _refreshCompleter.future;
  }

  void _loadPost() {
    BlocProvider.of<PostsBloc>(context).add(LoadPosts());
  }

  void _loadMorePost(int page) {
    BlocProvider.of<PostsBloc>(context).add(LoadMorePosts(page));
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
        child: BlocBuilder<PostsBloc, PostsState>(builder: (context, state) {
          if (state is PostsLoaded) {
            return LazyLoadScrollView(
              onEndOfPage: () => _loadMorePost(currentPage + 1),
              child: ListView.separated(
                separatorBuilder: (context, index) =>
                    Container(color: Colors.white30, height: 0.5),
                itemCount: state.posts == null ? 0 : state.posts.length,
                itemBuilder: (BuildContext context, int index) {
                  Post post = state.posts[index];
                  return CardArticle(
                    title: post.title.rendered,
                    shortContent: post.excerpt.rendered,
                    date: post.date,
                    onTap: () {
                      Navigation.intentWithData(
                        context,
                        DetailArticle.routeName,
                        ScreenArguments(
                          post.id,
                          post.title.rendered,
                          post.excerpt.rendered,
                          post.content.rendered,
                          post.slug,
                        ),
                      );
                    },
                  );
                },
              ),
            );
          } else if (state is PostsLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is PostsNotLoaded) {
            return Padding(
              padding: EdgeInsets.all(Sizes.dp16(context)),
              child: Center(child: Text(state.errorMessage)),
            );
          } else {
            return Center(child: Text(""));
          }
        }),
        onRefresh: _refresh);
  }
}
