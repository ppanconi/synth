#library('synthesizer');

#import('dart:io');

const String GET = 'GET';
const String POST = 'POST';

final Map getRoutes = new Map();
final Map postRoutes = new Map();

void route(final String method, final String path,
           void handler(final HttpRequest req, final SynthResponse res)) {
  switch (method) {
    case GET:
      getRoutes[path] = handler;
      break;
    case POST:
      postRoutes[path] = handler;
      break;
  }
}

Map _retrieveRouteMap(final String method) {
  Map routeMap = null;

  switch (method) {
    case GET:
      routeMap = getRoutes;
      break;
    case POST:
      routeMap = postRoutes;
      break;
  }

  return routeMap;
}

class SynthResponse implements HttpResponse {
  HttpResponse _res;

  SynthResponse(this._res);

  void write(String content) {
    outputStream.write(content.charCodes());
  }

  int get contentLength => _res.contentLength;
  int get statusCode => _res.statusCode;
  String get reasonPhrase => _res.reasonPhrase;
  bool get persistentConnection => _res.persistentConnection;
  HttpHeaders get headers => _res.headers;
  List<Cookie> get cookies => _res.cookies;
  OutputStream get outputStream => _res.outputStream;
  DetachedSocket detachSocket() => _res.detachSocket();
  HttpConnectionInfo get connectionInfo => _res.connectionInfo;
}

class SynthHandler {
  String path;
  var handler;

  SynthHandler(this.path, this.handler);
}

class Router {

  static SynthHandler matchHandler(final HttpRequest req) {
    SynthHandler handler = null;
    final Map routeMap = _retrieveRouteMap(req.method);
    final String path = req.path;

    if ('/' == path) {
      handler = new SynthHandler(path, routeMap['/']);
    } else {
      handler = _matchPathToRoutes(path, routeMap);
    }

    return handler;
  }

  static SynthHandler _matchPathToRoutes(final String path, final Map routeMap) {
    SynthHandler handler = null;
    Collection<String> routes = routeMap.getKeys();
    for (String route in routes) {
      bool matched = _matchPathToRoute(path, route);

      if (matched) {
        handler = new SynthHandler(route, routeMap[route]);
        break;
      }
    }

    return handler;
  }

  static bool _matchPathToRoute(String path, String route) {
    bool matched = false;

    SynthHandler handler = null;
    path = _removeLastForwardSlashFromUrl(path);
    route = _removeLastForwardSlashFromUrl(route);

    List<String> pathNodes = path.split('/');
    List<String> routeNodes = route.split('/');

    if (pathNodes.length == routeNodes.length) {
      for (int i = 0; i < pathNodes.length; i++) {
        final String pathNode = pathNodes[i];
        final String routeNode = routeNodes[i];
        matched = _matchPathNodeToRouteNode(pathNode, routeNode);
        if (!matched) {
          break;
        }
      }
    }

    return matched;
  }

  static bool _matchPathNodeToRouteNode(final String pathNode, final String routeNode) {
    bool matched = false;
    if (routeNode.startsWith(':')) {
      matched = true;
    } else {
      matched = pathNode == routeNode;
    }

    return matched;
  }

}

String _removeLastForwardSlashFromUrl(String path) {
  return path.endsWith('/') ? path.substring(0, path.length - 1) : path;
}