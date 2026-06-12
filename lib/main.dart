import 'package:flutter/material.dart';

void main() {
  runApp(const MiAppClinica());
}

class MiAppClinica extends StatelessWidget {
  const MiAppClinica({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Clínico y Pagos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  // Datos de prueba (Luego los conectaremos de forma automatizada)
  final double tasaBCV = 36.50; 
  final double margenBs = 35.0; // Margen personalizado sobre el BCV

  // Lista inicial de pacientes con su historia clínica y cuotas estilo Cashea
  final List<Map<String, dynamic>> pacientes = [
    {
      'nombre': 'Carlos Mendoza',
      'cedula': 'V-14.567.890',
      'historia': 'Paciente presenta miopía y astigmatismo. Se recetaron lentes correctivos con filtro azul.',
      'montoTotalDolares': 120.0,
      'cuotasPendientes': 3,
      'proximaFechaPago': '18/06/2026',
    },
    {
      'nombre': 'María Rodríguez',
      'cedula': 'V-20.123.456',
      'historia': 'Evaluación de control por sospecha de pterigión. Se indica tratamiento lubricante cada 8 horas.',
      'montoTotalDolares': 80.0,
      'cuotasPendientes': 1,
      'proximaFechaPago': '25/06/2026',
    }
  ];

  @override
  Widget build(BuildContext context) {
    double tasaCalculada = tasaBCV + margenBs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pacientes y Cuotas'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel Financiero Tasa del Día
            Card(
              color: Colors.blue[50],
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tasa BCV: ${tasaBCV.toStringAsFixed(2)} Bs.', style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Tu Tasa (+${margenBs.toStringAsFixed(0)} En.):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Text(
                      '${tasaCalculada.toStringAsFixed(2)} Bs.',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Lista de Clientes / Pacientes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Lista desplegable de Pacientes
            Expanded(
              child: ListView.builder(
                itemCount: pacientes.length,
                itemBuilder: (context, index) {
                  final paciente = pacientes[index];
                  // Cálculo de saldo restante en base a cuotas y tasa dinámica
                  double saldoRestanteBs = (paciente['montoTotalDolares'] / 4) * paciente['cuotasPendientes'] * tasaCalculada;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ExpansionTile(
                      leading: Icon(Icons.person, color: Colors.blue[800], size: 40),
                      title: Text(paciente['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('C.I: ${paciente['cedula']}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const Text('Historial Clínico:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(paciente['historia']),
                              const Divider(),
                              Text('Financiamiento (Estilo Cashea):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900])),
                              const SizedBox(height: 6),
                              Text('Cuotas por pagar: ${paciente['cuotasPendientes']} restantes'),
                              const SizedBox(height: 2),
                              Text('Próxima fecha de vencimiento: ${paciente['proximaFechaPago']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 2),
                              Text('Saldo estimado al día: ${saldoRestanteBs.toStringAsFixed(2)} Bs.', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {}, // Espacio para la función de agregar pacientes más adelante
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}