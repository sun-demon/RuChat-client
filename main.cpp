#include <QGuiApplication>
#include <QIcon>
#include <QTextCodec>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "utils.h"
#include "tcpclient.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QTextCodec::setCodecForLocale(QTextCodec::codecForName("UTF-8"));

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/chat.png"));

    Utils utils{};
    TcpClient tcpClient{};

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("utils", &utils);
    engine.rootContext()->setContextProperty("tcpClient", &tcpClient);
    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
