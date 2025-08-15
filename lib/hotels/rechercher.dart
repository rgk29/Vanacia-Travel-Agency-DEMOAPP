import 'package:agencedevoyage/hotels/resultat.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:agencedevoyage/hotels/data.dart';

// Couleurs communes
const Color primaryBlue = Color(0xFF2A5C82);
const Color secondaryBlue = Color(0xFF3AB795);
const Color accentOrange = Color(0xFFFF7F50);

class HotelSearchScreen extends StatelessWidget {
  final String? preFilledLocation;
  final DateTime? arrivalDate;
  const HotelSearchScreen({
    super.key,
    this.preFilledLocation,
    this.arrivalDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('hotel_search_title'.tr(),
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, secondaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: HotelSearchForm(
        preFilledLocation: preFilledLocation,
        arrivalDate: arrivalDate,
      ),
    );
  }
}

class HotelSearchForm extends StatefulWidget {
  final String? preFilledLocation;
  final DateTime? arrivalDate;
  const HotelSearchForm({
    super.key,
    this.preFilledLocation,
    this.arrivalDate,
  });

  @override
  HotelSearchFormState createState() => HotelSearchFormState();
}

class HotelSearchFormState extends State<HotelSearchForm> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _hotelController = TextEditingController();

  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adults = 1;
  int _children = 0;
  int _teens = 0;

  @override
  void initState() {
    super.initState();
    // Pré-remplissage des données
    if (widget.preFilledLocation != null) {
      _countryController.text = widget.preFilledLocation!;
    }
    if (widget.arrivalDate != null) {
      _checkInDate = widget.arrivalDate!;
      _checkOutDate = _checkInDate!.add(const Duration(days: 1));
    }
  }

  String get _duration {
    if (_checkInDate != null && _checkOutDate != null) {
      return '${_checkOutDate!.difference(_checkInDate!).inDays} ${'night'.tr()}';
    }
    return '';
  }

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    DateTime initialDate = isCheckIn
        ? (_checkInDate ?? DateTime.now())
        : (_checkOutDate ??
            _checkInDate?.add(const Duration(days: 1)) ??
            DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isCheckIn ? DateTime.now() : (_checkInDate ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      selectableDayPredicate: (DateTime date) {
        if (isCheckIn) return true;
        return date.isAfter(
            _checkInDate ?? DateTime.now().subtract(const Duration(days: 1)));
      },
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate == null || _checkOutDate!.isBefore(picked)) {
            _checkOutDate = picked.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  List<String> _getSuggestions(String type, String query) {
    final cleanQuery = query.toLowerCase();
    if (cleanQuery.isEmpty) return [];

    switch (type) {
      case 'country':
        return localHotels
            .where((h) => h.address.country.toLowerCase().contains(cleanQuery))
            .map((h) => h.address.country)
            .toSet()
            .toList();
      case 'province':
        return localHotels
            .where((h) => h.address.province.toLowerCase().contains(cleanQuery))
            .map((h) => h.address.province)
            .toSet()
            .toList();
      case 'hotel':
        return localHotels
            .where((h) => h.name.toLowerCase().contains(cleanQuery))
            .map((h) => h.name)
            .toList();
      default:
        return [];
    }
  }

  Widget _buildSearchField(String typeKey, String hintKey, IconData icon) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        return _getSuggestions(typeKey, textEditingValue.text);
      },
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: typeKey.tr(), // Traduction du type (ex. "Hôtel")
            hintText: hintKey.tr(), // Traduction du hint (ex. "Nom de l'hôtel")
            prefixIcon: Icon(icon, color: Colors.blue[800]),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          onChanged: (value) => setState(() {}),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateCard(String label, DateTime? date, bool isCheckIn) {
    return Expanded(
      child: InkWell(
        onTap: () => _selectDate(context, isCheckIn),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              SizedBox(height: 8),
              Text(
                  date != null
                      ? DateFormat('dd/MM/yyyy').format(date)
                      : '--/--/----',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              if (date != null) ...[
                SizedBox(height: 4),
                Text(DateFormat('EEEE', 'fr').format(date),
                    style: TextStyle(color: primaryBlue, fontSize: 14)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerCounter(String title, int value,
      VoidCallback onIncrement, VoidCallback onDecrement) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 16)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove, color: primaryBlue),
                onPressed: onDecrement,
              ),
              Container(
                width: 30,
                alignment: Alignment.center,
                child: Text('$value', style: TextStyle(fontSize: 16)),
              ),
              IconButton(
                icon: Icon(Icons.add, color: primaryBlue),
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSearchField('hotel', 'hotel_name_optional', Icons.hotel),
          SizedBox(height: 16),
          _buildSearchField('country', 'Pays_de_destination', Icons.public),
          SizedBox(height: 16),
          _buildSearchField(
              'province', 'Ville_ou_Province', Icons.location_city),
          SizedBox(height: 24),
          Row(
            children: [
              _buildDateCard('Arrivée'.tr(), _checkInDate, true),
              SizedBox(width: 16),
              _buildDateCard('Départ'.tr(), _checkOutDate, false),
            ],
          ),
          if (_checkInDate != null && _checkOutDate != null) ...[
            SizedBox(height: 16),
            Text('${'Durée_du_séjour'.tr()}: $_duration',
                style:
                    TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
          ],
          SizedBox(height: 24),
          Column(
            children: [
              _buildPassengerCounter(
                  'Adultes'.tr(),
                  _adults,
                  () => setState(() => _adults++),
                  () => setState(() => _adults > 1 ? _adults-- : null)),
              SizedBox(height: 12),
              _buildPassengerCounter(
                  'Enfants'.tr(),
                  _children,
                  () => setState(() => _children++),
                  () => setState(() => _children > 0 ? _children-- : null)),
              SizedBox(height: 12),
              _buildPassengerCounter(
                  'Ados'.tr(),
                  _teens,
                  () => setState(() => _teens++),
                  () => setState(() => _teens > 0 ? _teens-- : null)),
            ],
          ),
          SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_checkInDate == null || _checkOutDate == null) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Champs_manquants'.tr()),
                      content: Text('select_stay_dates'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('OK'.tr()),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelResultsPage(
                        checkInDate: _checkInDate!,
                        checkOutDate: _checkOutDate!,
                        // Valeur dynamique
                      ),
                    ),
                  );
                }
              },
              child: Text('Rechercher'.tr(),
                  style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
