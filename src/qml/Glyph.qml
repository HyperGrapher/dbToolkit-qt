pragma ComponentBehavior: Bound
import QtQuick

Canvas {
    id: icon
    property string name: "database"
    property color ink: Theme.muted
    implicitWidth: 20
    implicitHeight: 20
    onNameChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d");
        c.reset();
        c.scale(width / 24, height / 24);
        c.strokeStyle = ink;
        c.lineWidth = 1.6;
        c.lineCap = "round";
        c.lineJoin = "round";
        function line(points) {
            c.beginPath();
            c.moveTo(points[0], points[1]);
            for (let i = 2; i < points.length; i += 2)
                c.lineTo(points[i], points[i + 1]);
            c.stroke();
        }
        function box(x, y, w, h) {
            c.strokeRect(x, y, w, h);
        }
        function circle(x, y, r) {
            c.beginPath();
            c.arc(x, y, r, 0, Math.PI * 2);
            c.stroke();
        }
        switch (name) {
        case "database":
            c.beginPath();
            c.ellipse(4, 3, 16, 6);
            c.stroke();
            line([4, 6, 4, 18]);
            line([20, 6, 20, 18]);
            c.beginPath();
            c.moveTo(4, 12);
            c.bezierCurveTo(4, 16, 20, 16, 20, 12);
            c.stroke();
            c.beginPath();
            c.moveTo(4, 18);
            c.bezierCurveTo(4, 23, 20, 23, 20, 18);
            c.stroke();
            break;
        case "grid":
            box(4, 4, 6, 6);
            box(14, 4, 6, 6);
            box(4, 14, 6, 6);
            box(14, 14, 6, 6);
            break;
        case "server":
            box(3, 4, 18, 6);
            box(3, 14, 18, 6);
            line([7, 7, 8, 7]);
            line([7, 17, 8, 17]);
            break;
        case "table":
            box(3, 4, 18, 16);
            line([3, 10, 21, 10]);
            line([9, 10, 9, 20]);
            break;
        case "download":
            line([12, 3, 12, 15]);
            line([7, 10, 12, 15, 17, 10]);
            line([4, 16, 4, 21, 20, 21, 20, 16]);
            break;
        case "plus":
            line([12, 5, 12, 19]);
            line([5, 12, 19, 12]);
            break;
        case "search":
            circle(10, 10, 6);
            line([15, 15, 21, 21]);
            break;
        case "chevron":
            line([9, 6, 15, 12, 9, 18]);
            break;
        case "down":
            line([7, 10, 12, 15, 17, 10]);
            break;
        case "arrow":
            line([4, 12, 20, 12]);
            line([14, 6, 20, 12, 14, 18]);
            break;
        case "refresh":
            c.beginPath();
            c.arc(12, 12, 8, 0.5, 5.5);
            c.stroke();
            line([18, 3, 18, 8, 13, 8]);
            break;
        case "check":
            line([5, 12, 10, 17, 19, 7]);
            break;
        case "close":
            line([6, 6, 18, 18]);
            line([18, 6, 6, 18]);
            break;
        case "copy":
            box(8, 8, 12, 13);
            line([15, 4, 4, 4, 4, 16]);
            break;
        case "more":
            circle(5, 12, 0.8);
            circle(12, 12, 0.8);
            circle(19, 12, 0.8);
            break;
        case "filter":
            line([3, 5, 21, 5, 14, 13, 14, 19, 10, 21, 10, 13, 3, 5]);
            break;
        case "folder":
            line([3, 7, 3, 20, 21, 20, 21, 7, 12, 7, 9, 4, 3, 4, 3, 7]);
            break;
        case "clock":
            circle(12, 12, 9);
            line([12, 6, 12, 12, 16, 14]);
            break;
        case "settings":
            circle(12, 12, 4);
            circle(12, 12, 8);
            line([12, 1, 12, 4]);
            line([12, 20, 12, 23]);
            line([1, 12, 4, 12]);
            line([20, 12, 23, 12]);
            break;
        case "power":
            c.beginPath();
            c.arc(12, 13, 8, -0.9, 4.05);
            c.stroke();
            line([12, 2, 12, 11]);
            break;
        case "code":
            line([8, 6, 2, 12, 8, 18]);
            line([16, 6, 22, 12, 16, 18]);
            break;
        case "shield":
            line([12, 2, 21, 6, 20, 15, 12, 22, 4, 15, 3, 6, 12, 2]);
            line([8, 12, 11, 15, 16, 9]);
            break;
        case "eye":
            c.beginPath();
            c.moveTo(2, 12);
            c.bezierCurveTo(6, 5, 18, 5, 22, 12);
            c.bezierCurveTo(18, 19, 6, 19, 2, 12);
            c.stroke();
            circle(12, 12, 2.5);
            break;
        case "upload":
            line([12, 21, 12, 7]);
            line([7, 12, 12, 7, 17, 12]);
            line([4, 4, 4, 3, 20, 3, 20, 4]);
            break;
        default:
            circle(12, 12, 8);
            line([12, 10, 12, 16]);
            circle(12, 7, 0.5);
        }
    }
}
