import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

import 'package:band_names/models/band.dart';
import 'package:band_names/services/socket_services.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];
  // Band(id: '1', name: 'ACDC', votes: 1),
  // Band(id: '2', name: 'Queen', votes: 4),
  // Band(id: '3', name: 'Enrique Bunbury', votes: 6),
  // Band(id: '4', name: 'Muse', votes: 3),
  // Band(id: '5', name: 'Bon Jovi', votes: 5),

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    this.bands = (payload as List).map((band) => Band.fromMap(band)).toList();

    setState(() {});
  }

  // @override
  // void dispose() {
  //   final socketService = Provider.of<SocketService>(context, listen: false);
  //   socketService.socket.off('active-bands');
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            Text('Bandas Favoritas', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 10),
            child: (socketService.serverStatus == ServerStatus.Online)
                ? Icon(Icons.thumb_up, color: Colors.green[300])
                : Icon(Icons.thumb_down, color: Colors.red[300]),
          ),
        ],
      ),
      body: Column(
        children: [
          _mostrarGraficas(),
          Expanded(
            child: ListView.builder(
                physics: BouncingScrollPhysics(),
                itemCount: bands.length,
                itemBuilder: (context, i) => _bandTile(bands[i])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        elevation: 1,
        onPressed: addNewBand,
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) =>
          socketService.socket.emit('delete-band', {'id': band.id}),
      background: Container(
        padding: EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text('Eliminar Banda',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
              )),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(band.name.substring(0, 2)),
          backgroundColor: Colors.blue[100],
        ),
        title: Text(band.name),
        trailing: Text('${band.votes}', style: TextStyle(fontSize: 20)),
        onTap: () => socketService.socket.emit('vote-band', {'id': band.id}),
      ),
    );
  }

  addNewBand() {
    final textController = new TextEditingController();

    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (_) => AlertDialog(
                title: Text('Nueva Banda'),
                content: TextField(
                  controller: textController,
                ),
                actions: [
                  MaterialButton(
                    child: Text('Agregar'),
                    elevation: 5,
                    onPressed: () => addBandToList(textController.text),
                  )
                ],
              ));
    }

    showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
              title: Text('Nueva Banda'),
              content: CupertinoTextField(
                controller: textController,
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('Agregar'),
                  onPressed: () => addBandToList(textController.text),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ));
  }

  void addBandToList(String name) {
    if (name.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);

      socketService.socket.emit('add-band', {'name': name});
    }
    Navigator.pop(context);
  }

  Widget _mostrarGraficas() {
    // Map<String, double> dataMap = {"Flutter": 5);
    Map<String, double> dataMap = new Map();
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return Container(
        width: double.infinity,
        height: 200,
        child: PieChart(
          dataMap: dataMap,
          initialAngleInDegree: 0,
          legendOptions: LegendOptions(),
          chartValuesOptions: ChartValuesOptions(
            showChartValuesInPercentage: true,
            showChartValues: true,
          ),
        ));
  }
}
