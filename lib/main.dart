import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiAppClinica());
}

class MiAppClinica extends StatelessWidget {
  const MiAppClinica({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Clínico y Ventas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        fontFamily: 'Roboto',
      ),
      home: const DashboardPrincipal(),
    );
  }
}

class DashboardPrincipal extends StatefulWidget {
  const DashboardPrincipal({Key? key}) : super(key: key);

  @override
  State<DashboardPrincipal> createState() => _DashboardPrincipalState();
}

class _DashboardPrincipalState extends State<DashboardPrincipal> {
  double _tasaActual = 700.0;
  List<Map<String, dynamic>> _historialTasas = [];
  List<Map<String, dynamic>> _pacientes = [];
  List<Map<String, dynamic>> _ventas = [];

  final TextEditingController _tasaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // --- PERSISTENCIA DE DATOS CON SHARED PREFERENCES ---
  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tasaActual = prefs.getDouble('tasaActual') ?? 700.0;
      _tasaController.text = _tasaActual.toStringAsFixed(2);
      
      String? historialJson = prefs.getString('historialTasas');
      if (historialJson != null) _historialTasas = List<Map<String, dynamic>>.from(json.decode(historialJson));

      String? pacientesJson = prefs.getString('pacientes');
      if (pacientesJson != null) _pacientes = List<Map<String, dynamic>>.from(json.decode(pacientesJson));

      String? ventasJson = prefs.getString('ventas');
      if (ventasJson != null) _ventas = List<Map<String, dynamic>>.from(json.decode(ventasJson));
    });
  }

  Future<void> _guardarDatos(String llave, dynamic datos) async {
    final prefs = await SharedPreferences.getInstance();
    if (datos is double) {
      await prefs.setDouble(llave, datos);
    } else {
      await prefs.setString(llave, json.encode(datos));
    }
  }

  void _actualizarTasa() {
    double? nuevaTasa = double.tryParse(_tasaController.text);
    if (nuevaTasa != null && nuevaTasa > 0) {
      setState(() {
        _tasaActual = nuevaTasa;
        _historialTasas.insert(0, {
          'fecha': DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now()),
          'tasa': _tasaActual,
        });
      });
      _guardarDatos('tasaActual', _tasaActual);
      _guardarDatos('historialTasas', _historialTasas);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tasa actualizada a ${_tasaActual.toStringAsFixed(2)} Bs.')),
      );
    }
  }

  // --- DIÁLOGOS Y VENTANAS ---
  void _mostrarOpcionesMas() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.teal),
              title: const Text('Nuevo Cliente / Paciente'),
              onTap: () {
                Navigator.pop(context);
                _abrirFormularioPaciente();
              },
            ),
            ListTile(
              leading: const Icon(Icons.point_of_sale, color: Colors.teal),
              title: const Text('Nueva Venta / Planilla de Pago'),
              onTap: () {
                Navigator.pop(context);
                if (_pacientes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Primero debes registrar al menos un paciente.')),
                  );
                } else {
                  _abrirFormularioVenta();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _abrirFormularioPaciente() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FormularioPaciente(
      onGuardar: (nuevoPaciente) {
        setState(() {
          _pacientes.add(nuevoPaciente);
        });
        _guardarDatos('pacientes', _pacientes);
      },
    )));
  }

  void _abrirFormularioVenta() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => FormularioVenta(
      pacientes: _pacientes,
      tasaActual: _tasaActual,
      onGuardar: (nuevaVenta) {
        setState(() {
          _ventas.add(nuevaVenta);
        });
        _guardarDatos('ventas', _ventas);
      },
    )));
  }

  void _verHistorialTasas() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Historial de Cambios de Tasa'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _historialTasas.isEmpty
              ? const Center(child: Text('No hay registros de cambios.'))
              : ListView.builder(
                  itemCount: _historialTasas.length,
                  itemBuilder: (context, index) {
                    final item = _historialTasas[index];
                    return ListTile(
                      leading: const Icon(Icons.trending_up, color: Colors.orange),
                      title: Text('${item['tasa'].toStringAsFixed(2)} Bs.'),
                      subtitle: Text('${item['fecha']}'),
                    );
                  },
                ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  void _generarMensajeCobro(Map<String, dynamic> venta) {
    String mensaje = 
        "*RECORDATORIO DE PAGO - CONTROL CLÍNICO*\n\n"
        "Estimado(a) *${venta['pacienteNombre']}*,\n"
        "Le saludamos cordialmente. Le recordamos los detalles económicos de su presupuesto:\n\n"
        "• *Monto Total:* \$${venta['totalDolares'].toStringAsFixed(2)} (${venta['totalBolivares'].toStringAsFixed(2)} Bs.)\n"
        "• *Abonado:* \$${venta['abonadoDolares'].toStringAsFixed(2)} (${venta['abonadoBolivares'].toStringAsFixed(2)} Bs.)\n"
        "• *Restante por Pagar:* *\$${venta['restanteDolares'].toStringAsFixed(2)}* (*${venta['restanteBolivares'].toStringAsFixed(2)} Bs.*)\n\n"
        "• *Fecha de Próxima Cuota:* ${venta['fechaPago']}\n\n"
        "_Calculado bajo la tasa activa de ${venta['tasaAplicada'].toStringAsFixed(2)} Bs._\n"
        "Por favor, reporte su pago a la brevedad. ¡Feliz día!";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mensaje Personalizado'),
        content: SingleChildScrollView(child: SelectableText(mensaje)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensaje listo para copiar.')));
            },
            child: const Text('Aceptar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clínica', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.teal,
        elevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.history, color: Colors.white), onPressed: _verHistorialTasas, title: 'Historial de Tasas'),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- BLOQUE TASA EDITABLE ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tasaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tasa del Día ($1.00 = Bs.)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on, color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _actualizarTasa,
                      child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECCIÓN CALENDARIO / PRÓXIMOS COBROS ---
            Row(
              children: const [
                Icon(Icons.calendar_month, color: Colors.teal),
                SizedBox(width: 8),
                Text('Calendario de Próximas Cuotas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            _ventas.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No hay cuentas pendientes en el calendario.', style: TextStyle(color: Colors.grey))),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ventas.length,
                    itemBuilder: (context, index) {
                      final v = _ventas[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.hourglass_empty, color: Colors.white)),
                          title: Text(v['pacienteNombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Debe: \$${v['restanteDolares'].toStringAsFixed(2)} | Vence: ${v['fechaPago']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.message, color: Colors.teal),
                            onPressed: () => _generarMensajeCobro(v),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _mostrarOpcionesMas,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }
}

// --- VENTANA 1: FORMULARIO HISTORIA CLÍNICA ---
class FormularioPaciente extends StatefulWidget {
  final Function(Map<String, dynamic>) onGuardar;
  const FormularioPaciente({Key? key, Required this.onGuardar}) : super(key: key);

  @override
  State<FormularioPaciente> createState() => _FormularioPacienteState();
}

class _FormularioPacienteState extends State<FormularioPaciente> {
  final _formKey = GlobalKey<FormState>();
  final _cedula = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _edad = TextEditingController();
  final _antecedentesMedicos = TextEditingController();
  final _antecedentesOculares = TextEditingController();
  final _diagnostico = TextEditingController();
  final _tratamiento = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Historia Clínica', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _cedula, decoration: const InputDecoration(labelText: 'Cédula de Identidad'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _nombre, decoration: const InputDecoration(labelText: 'Nombre y Apellido completo'), validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _telefono, decoration: const InputDecoration(labelText: 'Número de Teléfono'), keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _edad, decoration: const InputDecoration(labelText: 'Edad'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Campo requerido' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _antecedentesMedicos, decoration: const InputDecoration(labelText: 'Antecedentes Médicos Generales'), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _antecedentesOculares, decoration: const InputDecoration(labelText: 'Antecedentes Oculares / Optométricos'), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _diagnostico, decoration: const InputDecoration(labelText: 'Diagnóstico Clínico'), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _tratamiento, decoration: const InputDecoration(labelText: 'Tratamiento / Indicaciones de lentes'), maxLines: 2),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(16)),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onGuardar({
                    'cedula': _cedula.text,
                    'nombre': _nombre.text,
                    'telefono': _telefono.text,
                    'edad': _edad.text,
                    'antecedentesMedicos': _antecedentesMedicos.text,
                    'antecedentesOculares': _antecedentesOculares.text,
                    'diagnostico': _diagnostico.text,
                    'tratamiento': _tratamiento.text,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Registrar Historia Clínica', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// --- VENTANA 2: PLANILLA DE PAGO Y CÁLCULOS ---
class FormularioVenta extends StatefulWidget {
  final List<Map<String, dynamic>> pacientes;
  final double tasaActual;
  final Function(Map<String, dynamic>) onGuardar;

  const FormularioVenta({Key? key, Required this.pacientes, required this.tasaActual, required this.onGuardar}) : super(key: key);

  @override
  State<FormularioVenta> createState() => _FormularioVentaState();
}

class _FormularioVentaState extends State<FormularioVenta> {
  final _formKey = GlobalKey<FormState>();
  String? _pacienteSeleccionado;
  final _totalUSD = TextEditingController();
  final _abonoUSD = TextEditingController();
  
  double _totalBS = 0.0;
  double _abonoBS = 0.0;
  double _restanteUSD = 0.0;
  double _restanteBS = 0.0;
  
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 15));

  void _realizarCalculos() {
    double total = double.tryParse(_totalUSD.text) ?? 0.0;
    double abono = double.tryParse(_abonoUSD.text) ?? 0.0;

    setState(() {
      _totalBS = total * widget.tasaActual;
      _abonoBS = abono * widget.tasaActual;
      _restanteUSD = total - abono;
      _restanteBS = _restanteUSD * widget.tasaActual;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Planilla de Venta / Pago', style: TextStyle(color: Colors.white)), backgroundColor: Colors.teal),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Seleccionar Paciente'),
              items: widget.pacientes.map((p) {
                return DropdownMenuItem<String>(value: p['nombre'], child: Text(p['nombre']));
              }).toList(),
              onChanged: (val) => setState(() => _pacienteSeleccionado = val),
              validator: (v) => v == null ? 'Seleccione un paciente' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalUSD,
              decoration: const InputDecoration(labelText: 'Monto Total Venta (\$)', prefixIcon: Icon(Icons.attach_money)),
              keyboardType: TextInputType.number,
              onChanged: (v) => _realizarCalculos(),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _abonoUSD,
              decoration: const InputDecoration(labelText: 'Abono Inicial (\$)', prefixIcon: Icon(Icons.money_off)),
              keyboardType: TextInputType.number,
              onChanged: (v) => _realizarCalculos(),
              validator: (v) => v!.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 20),
            
            // --- SECCIÓN DE RESULTADOS AUTOMÁTICOS ---
            Card(
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total en Bs:'), Text('${_totalBS.toStringAsFixed(2)} Bs.', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Abono en Bs:'), Text('${_abonoBS.toStringAsFixed(2)} Bs.', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Restante (\$):', style: TextStyle(color: Colors.red)), Text('\$${_restanteUSD.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Restante (Bs):', style: TextStyle(color: Colors.red)), Text('${_restanteBS.toStringAsFixed(2)} Bs.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- SECCIÓN FECHA DE PAGO ---
            ListTile(
              leading: const Icon(Icons.date_range, color: Colors.teal),
              title: const Text('Fecha Próxima Cuota'),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaSeleccionada)),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _fechaSeleccionada = picked);
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(16)),
              onPressed: () {
                if (_formKey.currentState!.validate() && _pacienteSeleccionado != null) {
                  widget.onGuardar({
                    'pacienteNombre': _pacienteSeleccionado,
                    'totalDolares': double.parse(_totalUSD.text),
                    'totalBolivares': _totalBS,
                    'abonadoDolares': double.parse(_abonoUSD.text),
                    'abonadoBolivares': _abonoBS,
                    'restanteDolares': _restanteUSD,
                    'restanteBolivares': _restanteBS,
                    'fechaPago': DateFormat('dd/MM/yyyy').format(_fechaSeleccionada),
                    'tasaAplicada': widget.tasaActual,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Procesar Venta y Cuota', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
