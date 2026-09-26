// lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countries Flag App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CountryListScreen(),
    );
  }
}

// 1. Data Models
class CountryResponse {
  final String status;
  final int totalCountries;
  final List<Country> countries;

  CountryResponse({
    required this.status,
    required this.totalCountries,
    required this.countries,
  });

  factory CountryResponse.fromJson(Map<String, dynamic> json) {
    var list = json['countries'] as List;
    List<Country> countryList = list.map((i) => Country.fromJson(i)).toList();

    return CountryResponse(
      status: json['status'],
      totalCountries: json['total_countries'],
      countries: countryList,
    );
  }
}

class Country {
  final String name;
  final String code;
  final String flag;

  Country({required this.name, required this.code, required this.flag});

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      name: json['name'],
      code: json['code'],
      flag: json['flag'],
    );
  }
}

// 2. Service using http.get()
class CountryService {
  Future<CountryResponse> fetchCountries() async {
    // Use an absolute or root-relative URL path for web deployment
    final Uri url = Uri.parse('/api/countries.json');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CountryResponse.fromJson(data);
    } else {
      throw Exception('Failed to load countries.json (Status: ${response.statusCode})');
    }
  }
}

// 3. UI Screen
class CountryListScreen extends StatefulWidget {
  const CountryListScreen({Key? key}) : super(key: key);

  @override
  _CountryListScreenState createState() => _CountryListScreenState();
}

class _CountryListScreenState extends State<CountryListScreen> {
  late Future<CountryResponse> futureCountries;

  @override
  void initState() {
    super.initState();
    futureCountries = CountryService().fetchCountries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('48 Countries Flags (HTTP Get)'),
      ),
      body: FutureBuilder<CountryResponse>(
        future: futureCountries,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.countries.isEmpty) {
            return const Center(child: Text('No countries found.'));
          }

          final countries = snapshot.data!.countries;

          return ListView.builder(
            itemCount: countries.length,
            itemBuilder: (context, index) {
              final country = countries[index];
              return ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(country.name),
                subtitle: Text('Code: ${country.code}'),
              );
            },
          );
        },
      ),
    );
  }
}
