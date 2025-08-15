import 'dart:async';

import 'package:agencedevoyage/vol/local_data.dart';
import 'package:agencedevoyage/vol/model.dart';
import 'package:agencedevoyage/vol/result_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

// Couleurs et styles communs
const Color primaryColor = Color(0xFF2A5C82);
const Color secondaryColor = Color(0xFF3AB795);
const Color accentColor = Color(0xFFFF7F50);
const TextStyle labelStyle = TextStyle(
  fontSize: 16,
  color: Color(0xFF4A4A4A),
  fontWeight: FontWeight.w500,
);

extension StringExtensions on String {
  bool equalsIgnoreCase(String other) => toLowerCase() == other.toLowerCase();
}

class FlightSearchPage extends StatefulWidget {
  const FlightSearchPage({super.key});

  @override
  FlightSearchPageState createState() => FlightSearchPageState();
}

class FlightSearchPageState extends State<FlightSearchPage>
    with TickerProviderStateMixin {
  // Ajout du mixin
  final _departController = TextEditingController();
  final _arrivalController = TextEditingController();
  DateTime _departureDate = DateTime.now();
  DateTime? _returnDate;
  bool _isRoundTrip = false;
  String _selectedClass = 'Economique'.tr();
  int selectedAdults = 1;
  int selectedTeens = 0;
  int selectedChildren = 0;
  bool _showWeatherAlert = false;
  final List<Map<String, dynamic>> _demoWeather = [];
  Timer? _weatherTimer;

  late AnimationController _alertController; // Retirer 'final'
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  List<Airport> _getAirportSuggestions(String query) {
    final queryLower = query.toLowerCase();
    return LocalData.airports.where((airport) {
      return airport.keywords.any((k) => k.contains(queryLower)) ||
          airport.code.toLowerCase().contains(queryLower) ||
          airport.city.toLowerCase().contains(queryLower);
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    _alertController = AnimationController(
      vsync: this, // Maintenant valide grâce au mixin
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _alertController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(
      parent: _alertController,
      curve: const Interval(0.3, 1, curve: Curves.easeIn), // Ajouter 'const'
    ));

    _initializeDemoWeather();
    _startWeatherTimer();
  }

  @override
  void dispose() {
    _alertController.dispose(); // Dispose du contrôleur
    _weatherTimer?.cancel();
    super.dispose();
  }

  void _startWeatherTimer() {
    _weatherTimer = Timer(const Duration(seconds: 20), () {
      if (mounted) {
        _alertController.forward();
        setState(() => _showWeatherAlert = true);
      }
    });
  }

  void _initializeDemoWeather() {
    final baseDate = DateTime(2025, 8, 15);
    _demoWeather.clear();

    for (int i = 0; i < 7; i++) {
      _demoWeather.add({
        'date': baseDate.add(Duration(days: i)),
        'temp': '${25 + i}°C',
        'condition': i.isEven ? 'sunny' : 'cloudy',
        'precipitation': i > 3 ? '${i * 10}%' : '0%',
      });
    }
  }

///////////////////////////////////////
  ///
  Widget _buildTripTypeSelector() {
    return Row(
      children: [
        _buildTripTypeChip('Aller_simple'.tr(), Icons.flight_takeoff, false),
        const SizedBox(width: 10),
        _buildTripTypeChip('Aller_retour'.tr(), Icons.flight_land, true),
      ],
    );
  }

  Widget _buildTripTypeChip(String label, IconData icon, bool isRoundTrip) {
    return ChoiceChip(
      label: Row(
        children: [Icon(icon, size: 18), const SizedBox(width: 5), Text(label)],
      ),
      selected: _isRoundTrip == isRoundTrip,
      onSelected: (selected) => setState(() {
        _isRoundTrip = selected ? isRoundTrip : !isRoundTrip;
        if (!_isRoundTrip) _returnDate = null;
      }),
    );
  }

  List<List<Flight>> _generateAllCombinations(
      List<Flight> departures, List<Flight> returns) {
    List<List<Flight>> combinations = [];
    for (var dep in departures) {
      for (var ret in returns) {
        if (dep.arrival.code == ret.departure.code) {
          combinations.add([dep, ret]);
        }
      }
    }
    return combinations;
  }

  void _searchFlights(BuildContext context) {
    final departure = _findAirport(_departController.text);
    final arrival = _findAirport(_arrivalController.text);

    if (departure == null || arrival == null) return;
    if (_isRoundTrip && _returnDate == null) {
      _showErrorDialog(
          context, 'Veuillez_sélectionner_une_date_de_retour'.tr());
      return;
    }
    // Vérifier que la date de retour est après la date d'aller
    if (_isRoundTrip && _returnDate!.isBefore(_departureDate)) {
      _showErrorDialog(
          context, 'La_date_de_retour_doit_être_après_la_date_daller'.tr());
      return;
    }
    if (departure.code == arrival.code) {
      _showErrorDialog(context,
          'Les_aéroports_de_départ_et_darrivée_doivent_être_différents'.tr());
      return;
    }
    final departureFlights =
        _findMatchingFlights(departure, arrival, _departureDate);
    final returnFlights = _isRoundTrip
        ? _findMatchingFlights(arrival, departure, _returnDate!)
        : [];

    if (_isRoundTrip) {
      final allCombinations = _generateAllCombinations(
        departureFlights,
        returnFlights.cast<Flight>(),
      );
      if (allCombinations.isEmpty) {
        _showNoResultsDialog(context);
        return;
      }
    }
    if (departureFlights.isEmpty || (_isRoundTrip && returnFlights.isEmpty)) {
      _showNoResultsDialog(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FlightResultsPage(
            departureFlights: departureFlights.cast<Flight>(), // Cast explicite
            returnFlights: returnFlights.cast<Flight>(), // Cast explicite
            isRoundTrip: _isRoundTrip,
            adults: selectedAdults,
            teens: selectedTeens,

            children: selectedChildren,
          ),
        ),
      );
    }
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Flight> _findMatchingFlights(Airport from, Airport to, DateTime date) {
    return LocalData.flights.where((flight) {
      final sameDay = DateUtils.isSameDay(flight.departureTime, date);
      final isClassMatch = flight.classe == _selectedClass;
      final isRouteMatch =
          flight.departure.code == from.code && flight.arrival.code == to.code;
      final matchesClass = flight.classe == _selectedClass;
      return sameDay && isClassMatch && isRouteMatch;
    }).toList();
  }

  Airport? _findAirport(String input) {
    try {
      final cleanedInput = input.trim();
      if (cleanedInput.contains(' - ')) {
        return LocalData.airports
            .firstWhere((a) => a.code == cleanedInput.split(' ').first);
      }
      return LocalData.airports.firstWhere((a) =>
          a.code.equalsIgnoreCase(cleanedInput) ||
          a.city.equalsIgnoreCase(cleanedInput) ||
          a.name.toLowerCase().contains(cleanedInput.toLowerCase()) ||
          a.keywords.any((k) => k.equalsIgnoreCase(cleanedInput)));
    } catch (e) {
      _showErrorDialog(context, """
Aéroport non trouvé pour : "$input"

tips
airportSearchTips """);
      return null;
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[800]),
            const SizedBox(width: 10),
            Text('Erreur'.tr()),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'.tr()),
          ),
        ],
      ),
    );
  }

  void _showNoResultsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Aucun_résultat'.tr()),
        content: Text('Aucun_vol_trouvé_pour_ces_critères'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche_de_vols'.tr(),
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                _buildTripTypeSelector(),
                SizedBox(height: 20),
                _buildAirportField(_departController, 'Départ'.tr()),
                SizedBox(height: 20),
                _buildAirportField(_arrivalController, 'Arrivée'.tr()),
                SizedBox(height: 20),
                _buildDateTile(
                  label: 'Date_daller'.tr(),
                  date: _departureDate,
                  onDateChanged: (date) =>
                      setState(() => _departureDate = date),
                ),
                if (_isRoundTrip) ...[
                  SizedBox(height: 20),
                  _buildDateTile(
                    label: 'Date_de_retour'.tr(),
                    date: _returnDate ?? _departureDate.add(Duration(days: 1)),
                    onDateChanged: (date) => setState(() => _returnDate = date),
                    firstDate: _departureDate,
                  ),
                ],
                if (_showWeatherAlert)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: _buildWeatherAlert(),
                  ),
                SizedBox(height: 20),
                _buildClassSelector(),
                SizedBox(height: 20),
                _buildPassengerSelector(),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => _searchFlights(context),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Rechercher'.tr(),
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

////////////////////////////
  ///
  Widget _buildWeatherAlert() {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.97),
                Colors.blue.shade50.withOpacity(0.97)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.blueGrey.withOpacity(0.15),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _showWeatherPreview,
              hoverColor: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.travel_explore,
                      color: primaryColor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Conseil_voyage'.tr(),
                          style: TextStyle(
                            color: Colors.blueGrey.shade800,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Météo_favorable_détectée'.tr(),
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeatherPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        contentPadding: const EdgeInsets.all(0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: SingleChildScrollView(
          // Ajout du scroll
          child: Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              // Contrainte de hauteur max
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWeatherHeader(),
                const SizedBox(height: 15),
                _buildWeatherTimeline(), // Fonction manquante ajoutée
                const SizedBox(height: 10),
                _buildWeatherDetails(), // Fonction manquante ajoutée
                const SizedBox(height: 10),
                _buildWeatherGrid(),
                const SizedBox(height: 10),
                _buildCloseButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherTimeline() {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        scrollDirection: Axis.horizontal,
        itemCount: _demoWeather.length,
        separatorBuilder: (_, __) => const SizedBox(width: 15),
        itemBuilder: (context, index) {
          final weather = _demoWeather[index];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.1),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTranslatedDay(weather['date']),
                        style: TextStyle(
                          color: Colors.blueGrey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _buildWeatherIcon(weather['condition']),
                      Column(
                        children: [
                          Text(
                            weather['temp'],
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            weather['precipitation'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherDetails() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildWeatherDetailItem(Icons.air, '15kmh', 'Vent'.tr()),
          _buildWeatherDetailItem(Icons.water_drop, '65%', 'Humidité'.tr()),
          _buildWeatherDetailItem(Icons.light_mode, 'UV 3', 'IndiceUV'.tr()),
        ],
      ),
    );
  }

  Widget _buildWeatherDetailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(height: 5),
        Text(value,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontWeight: FontWeight.bold,
            )),
        Text(label,
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 10,
            )),
      ],
    );
  }

  Widget _buildWeatherHeader() {
    return Row(
      children: [
        Icon(Icons.cloud, color: Colors.blueGrey[800], size: 30),
        const SizedBox(width: 7),
        Text(
          'Prévision_météo_15-22_Août_2025'.tr(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  // Modification de _buildWeatherGrid pour limiter la hauteur
  Widget _buildWeatherGrid() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 160, // Hauteur maximale fixe
      ),
      child: SingleChildScrollView(
        // Scroll horizontal
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 15,
          runSpacing: 15,
          children: _demoWeather
              .map((weather) => _buildWeatherCard(weather))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildWeatherCard(Map<String, dynamic> weather) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            '${DateFormat('dd').format(weather['date'])} ${getTranslatedMonth(weather['date'])}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildWeatherIcon(weather['condition']),
          const SizedBox(height: 8),
          Text(weather['temp'], style: const TextStyle(fontSize: 16)),
          Text(
            weather['precipitation'],
            style: TextStyle(
              color: Colors.blue.shade800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String condition) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: condition == 'sunny'
            ? Colors.amber.shade100
            : Colors.blueGrey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        condition == 'sunny' ? Icons.wb_sunny : Icons.cloud,
        color: condition == 'sunny' ? Colors.orange : Colors.blueGrey,
        size: 30,
      ),
    );
  }

  Widget _buildCloseButton() {
    return TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text(
        'Fermer'.tr(),
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onDateChanged,
    DateTime? firstDate,
    TextStyle? labelStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(label, style: labelStyle),
        trailing: Icon(Icons.calendar_today, color: primaryColor),
        subtitle: Text(DateFormat('dd/MM/yyyy').format(date)),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: firstDate ?? DateTime.now(),
            lastDate: DateTime.now().add(Duration(days: 730)),
            builder: (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(primary: primaryColor),
              ),
              child: child!,
            ),
          );
          if (picked != null) onDateChanged(picked);
        },
      ),
    );
  }

  String _getTranslatedDay(DateTime date) {
    final String dayKey =
        DateFormat('E', 'en').format(date); // 'E' avec locale anglaise
    return 'day_$dayKey'.tr(); // ex: "day_Mon"
  }

  String getTranslatedMonth(DateTime date) {
    final monthAbbr =
        DateFormat('MMM', 'en').format(date); // toujours en anglais
    final key = 'month_$monthAbbr'; // ex : month_Jan
    return key.tr();
  }

//////////////////////////////////////////
  ///
  Widget _buildDatePicker({
    required String label,
    required DateTime date,
    required ValueChanged<DateTime> onDateChanged,
    DateTime? firstDate,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 730)),
        );
        if (picked != null) onDateChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.calendar_today),
        ),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 20),
            const SizedBox(width: 10),
            Text(DateFormat('dd/MM/yyyy').format(date)),
          ],
        ),
      ),
    );
  }

  Widget _buildAirportField(TextEditingController controller, String label) {
    return Autocomplete<Airport>(
      optionsBuilder: (TextEditingValue value) {
        if (value.text.isEmpty) return Iterable<Airport>.empty();
        return _getAirportSuggestions(value.text);
      },
      displayStringForOption: (option) => '${option.code} - ${option.city}',
      onSelected: (Airport selection) {
        controller.text = '${selection.code} ';
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Ex_CDG_ou_Paris'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: secondaryColor, width: 2),
                borderRadius: BorderRadius.circular(10)),
            prefixIcon: Icon(Icons.flight_takeoff, color: primaryColor),
            filled: true,
            fillColor: Colors.white,
          ),
          onEditingComplete: onEditingComplete,
        );
      },
    );
  }

  Widget _buildClassSelector() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: DropdownButtonFormField<String>(
        value: _selectedClass,
        decoration: InputDecoration(
          labelText: 'Classe'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          prefixIcon:
              Icon(Icons.airline_seat_recline_normal, color: primaryColor),
        ),
        items: ['Economique'.tr(), 'Affaires'.tr(), 'Premiere'.tr()]
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (value) => setState(() => _selectedClass = value!),
      ),
    );
  }

  Widget _buildPassengerSelector() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Déplacer boxShadow dans BoxDecoration
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          // ✅ Correctement placé dans BoxDecoration
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passagers'.tr(),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor)),
          ..._buildPassengerCounters(),
        ],
      ),
    );
  }

  List<Widget> _buildPassengerCounters() {
    return [
      _buildPassengerCounter('Adultes_(18)'.tr(), selectedAdults,
          (v) => setState(() => selectedAdults = v)),
      _buildPassengerCounter('Enfants_(2_11_ans)'.tr(), selectedChildren,
          (v) => setState(() => selectedChildren = v)),
      _buildPassengerCounter('Ados_(12_17_ans)'.tr(), selectedTeens,
          (v) => setState(() => selectedTeens = v)),
    ];
  }

  Widget _buildPassengerCounter(
      String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.blue[700]),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text('$value', style: const TextStyle(fontSize: 16)),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.blue[700]),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
