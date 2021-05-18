import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: WebViewExample(),
    debugShowCheckedModeBanner: false,
  ));
}

class WebViewExample extends StatefulWidget {
  @override
  WebViewExampleState createState() => WebViewExampleState();
}

class WebViewExampleState extends State<WebViewExample> {
  final String client_id = '7833371'; // ЗДЕСЬ ПИШИТЕ ID ВАШЕГО ПРИЛОЖЕНИЯ
  String access_token = '';
  String user_id = '';
  String linkGetAccount = '';
  String first_name = '';
  String last_name = '';
  String photo_url = '';
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  void initState() {
    super.initState();
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
  }

  getAccessToken(context) async {
    var link = await context;
    var uri = Uri.parse(await link);
    access_token = uri.fragment.split('&')[0];
    access_token = access_token.split('=')[1];
    user_id = uri.fragment.split('&')[2];
    user_id = user_id.split('=')[1];
    var url = Uri.parse(
        'https://api.vk.com/method/users.get?user_id=${user_id}&access_token=${access_token}&v=5.52&fields=photo_200');
    var responseAccount = await http.get(url);
    first_name = jsonDecode(responseAccount.body)['response'][0]['first_name'];
    last_name = jsonDecode(responseAccount.body)['response'][0]['last_name'];
    photo_url = jsonDecode(responseAccount.body)['response'][0]['photo_200'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context,
            AsyncSnapshot<WebViewController> controller) {
          return Scaffold(
            body: Container(
              padding: EdgeInsets.only(
                  left: 0.0, top: 30.0, right: 0.0, bottom: 0.0),
              child: WebView(
                initialUrl:
                    'https://oauth.vk.com/authorize?client_id=${client_id}&display=page&redirect_uri=https://oauth.vk.com/blank.html&scope=friends&response_type=token&v=5.52',
                onWebViewCreated: (WebViewController webViewController) async {
                  _controller.complete(webViewController);
                },
               onProgress: (progress){
                  print(progress);
               },
                navigationDelegate: (NavigationRequest request) async {
                  if (request.url
                      .startsWith('https://oauth.vk.com/blank.html')) {
                    await getAccessToken(request.url);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SecondScreen(access_token,
                                first_name, last_name, photo_url, user_id)));
                  }
                  return NavigationDecision.navigate;
                },
              ),
            ),
          );
        });
  }
}

class SecondScreen extends StatefulWidget {
  @override
  String access_token = '';
  String first_name = '';
  String last_name = '';
  String photo_url = '';
  String user_id = '';

  SecondScreen(String _access_token, String _first_name, String _last_name,
      String _photo_url, String _user_id) {
    access_token = _access_token;
    first_name = _first_name;
    last_name = _last_name;
    photo_url = _photo_url;
    user_id = _user_id;
  }

  createState() => new SecondScreenState(
      access_token, first_name, last_name, photo_url, user_id);
}

class SecondScreenState extends State<SecondScreen> {
  String _access_token = '';
  String _first_name = '';
  String _last_name = '';
  String _photo_url = '';
  String _user_id = '';
  var friendsList;

  SecondScreenState(String access_token, String first_name, String last_name,
      String photo_url, String user_id) {
    _access_token = access_token;
    _first_name = first_name;
    _last_name = last_name;
    _photo_url = photo_url;
    _user_id = user_id;
  }

  setFriendsList() async {
    var url = Uri.parse(
        'https://api.vk.com/method/friends.get?user_id=$_user_id&access_token=$_access_token&v=5.110&fields=nickname,photo_50,online,domain,city,country,photo_200');
    var response = await http.get(url);
    //print(jsonDecode(response.body)['response']['items']);
    friendsList = jsonDecode(response.body)['response'];
    print(friendsList['items'][0]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('$_first_name $_last_name'),
          backgroundColor: Colors.deepPurpleAccent,
        ),
        drawer: Drawer(
          child: ListView(
            // Important: Remove any padding from the ListView.
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Center(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.values[2],
                        children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(200.0),
                        child: Image.network(
                          _photo_url,
                          height: 50.0,
                          width: 50.0,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(10.0),
                        child: Text(
                          _first_name,
                          style: TextStyle(color: Colors.white, fontSize: 20.0),
                        ),
                      )
                    ])),
                decoration: BoxDecoration(
                  color: Colors.deepPurpleAccent,
                ),
              ),
              ListTile(
                title: Text('Мой профиль'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Мои друзья'),
                onTap: () async {
                  if (friendsList == null) {
                    await setFriendsList();
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MyFriends(friendsList)));
                },
              ),
            ],
          ),
        ),
        body: Scaffold(
            body: Column(children: [
          SizedBox(
            height: 60.0,
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(75.0),
              child: Image.network(
                _photo_url,
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: Text(
              _first_name,
              style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              _last_name,
              style: TextStyle(fontSize: 40.0, fontWeight: FontWeight.bold),
            ),
          )
        ])));
  }
}

class MyFriends extends StatefulWidget {
  var friendlist;

  MyFriends(var _friendlist) {
    friendlist = _friendlist;
  }

  @override
  createState() => new MyFriendsState(friendlist);
}

class MyFriendsState extends State<MyFriends> {
  var _friendlist;

  MyFriendsState(var friendlist) {
    _friendlist = friendlist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Друзья'),
          backgroundColor: Colors.deepPurpleAccent,
        ),
        body: new ListView.builder(
          itemCount: _friendlist['count'],
          itemBuilder: (context, index) {
            return ListTile(
              leading: new ClipRRect(
                child: new Image.network(
                  _friendlist['items'][index]['photo_50'],
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.fill,
                ),
                borderRadius: BorderRadius.circular(200.0),
              ),
              title: new Text(
                  '${_friendlist['items'][index]['first_name'].toString()} ${_friendlist['items'][index]['last_name'].toString()}',
                  style: new TextStyle(fontSize: 15.0),
                  overflow: TextOverflow.ellipsis),
              onTap: () {
                if(_friendlist['items'][index]['country'] == null){
                  Navigator.push(
                      context,
                      PageRouteBuilder(
                          opaque: false,
                          pageBuilder: (BuildContext context, _, __) =>
                              MyOneFriend(
                                  _friendlist['items'][index]['first_name'],
                                  _friendlist['items'][index]['last_name'],
                                  _friendlist['items'][index]['photo_200'],
                                  ''
                              ),
                          transitionsBuilder: (___, Animation<double> animation,
                              ____, Widget child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          }));
                } else {
                Navigator.push(
                    context,
                    PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (BuildContext context, _, __) =>
                            MyOneFriend(
                              _friendlist['items'][index]['first_name'],
                              _friendlist['items'][index]['last_name'],
                              _friendlist['items'][index]['photo_200'],
                              _friendlist['items'][index]['country']['title']
                            ),
                        transitionsBuilder: (___, Animation<double> animation,
                            ____, Widget child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        }));
              }}
            );
          },
        ));
  }
}

class MyOneFriend extends StatelessWidget {
  String first_name = '';
  String last_name = '';
  String country = '';
  String photo_url = '';

  MyOneFriend(String _first_name, String _last_name, String _photo_url, String _country){
    first_name = _first_name;
    last_name = _last_name;
    photo_url = _photo_url;
    country = _country;
    if (country != ''){
      last_name = last_name + ',';
    }
  }



  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$first_name $last_name $country'),
      content: new ClipRRect(
        child: new Image.network(
          photo_url,
          width: 200.0,
          height: 200.0,
          fit: BoxFit.fitHeight,
        ),
        borderRadius: BorderRadius.circular(200.0),
      ),
      contentPadding: EdgeInsets.all(70.0),
      actions: [
        FlatButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Закрыть'),
        ),

      ],
    );
  }
}
