import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class Playerselection extends StatefulWidget {
  const Playerselection({super.key});

  @override
  State<Playerselection> createState() => _PlayerselectionState();
}

class _PlayerselectionState extends State<Playerselection>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> pokemons = [];
  final List<int> selectedPokemons = [];
  List<String> allTypes = [];
  String? selectedType;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> teams = []; // เพิ่มตัวแปรเก็บทีม
  String searchText = ''; // เพิ่มตัวแปรสำหรับค้นหา
  final box = GetStorage();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    fetchPokemons();
    // โหลด teams จาก storage
    final savedTeams = box.read<List>('teams');
    if (savedTeams != null) {
      teams = List<Map<String, dynamic>>.from(savedTeams);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchPokemons() async {
    final response = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=30'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List results = data['results'];
      List<Map<String, dynamic>> loaded = [];
      Set<String> typesSet = {};
      for (int i = 0; i < results.length; i++) {
        final pokeDetail = await http.get(Uri.parse(results[i]['url']));
        if (pokeDetail.statusCode == 200) {
          final detail = json.decode(pokeDetail.body);
          final types = (detail['types'] as List)
              .map((t) => t['type']['name'] as String)
              .toList();
          typesSet.addAll(types);
          loaded.add({
            'id': detail['id'],
            'name': detail['name'],
            'types': types,
            'image':
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/${detail['id']}.png',
          });
        }
      }
      setState(() {
        pokemons = loaded;
        allTypes = typesSet.toList()..sort();
      });
    }
  }

  void resetSelection() {
    setState(() {
      selectedPokemons.clear();
    });
  }

  Widget _buildAnimatedPopupMenu(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          alignment: Alignment.bottomCenter,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                  minWidth: 150,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.filter_alt, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'กรองตามประเภท',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Menu items
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildMenuItem('ทั้งหมด', null, Icons.apps),
                              const Divider(height: 1),
                              ...allTypes.map((type) => 
                                _buildMenuItem(type, type, _getTypeIcon(type))
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
      },
    );
  }

  Widget _buildMenuItem(String title, String? value, IconData icon) {
    final isSelected = selectedType == value;
    return InkWell(
      onTap: () {
        setState(() {
          selectedType = value;
        });
        Navigator.of(context).pop();
        _animationController.reverse();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red.withOpacity(0.1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.red : Colors.grey.shade600,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.red : Colors.black87,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.check,
                size: 16,
                color: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'fire': return Icons.local_fire_department;
      case 'water': return Icons.water_drop;
      case 'grass': return Icons.grass;
      case 'electric': return Icons.electric_bolt;
      case 'psychic': return Icons.psychology;
      case 'ice': return Icons.ac_unit;
      case 'dragon': return Icons.pets;
      case 'dark': return Icons.dark_mode;
      case 'fairy': return Icons.auto_awesome;
      case 'fighting': return Icons.sports_martial_arts;
      case 'poison': return Icons.dangerous;
      case 'ground': return Icons.landscape;
      case 'flying': return Icons.flight;
      case 'bug': return Icons.bug_report;
      case 'rock': return Icons.terrain;
      case 'ghost': return Icons.visibility_off;
      case 'steel': return Icons.hardware;
      default: return Icons.circle;
    }
  }

  Future<void> _showFilterMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero, ancestor: overlay);
    
    _animationController.forward();
    
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned(
              left: position.dx - 100,
              bottom: MediaQuery.of(context).size.height - position.dy + 10,
              child: _buildAnimatedPopupMenu(context),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.3),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: child,
        );
      },
    );
    
    _animationController.reverse();
  }

  Future<void> _showCreateTeamDialog() async {
    String teamName = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตั้งชื่อทีมของคุณ'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ชื่อทีม',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => teamName = value,
          onSubmitted: (value) {
            teamName = value;
            if (teamName.trim().isNotEmpty) {
              Navigator.pop(context, true);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              if (teamName.trim().isNotEmpty) {
                Navigator.pop(context, true);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กรุณาใส่ชื่อทีม')),
                );
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (result == true && teamName.trim().isNotEmpty) {
      final selectedPokemonData = pokemons
          .where((p) => selectedPokemons.contains(p['id']))
          .toList();

      setState(() {
        teams.add({
          'name': teamName.trim(),
          'pokemons': selectedPokemonData,
          'createdAt': DateTime.now().toIso8601String(),
        });
        selectedPokemons.clear();
        box.write('teams', teams); // <<--- เซฟ teams ทุกครั้งที่เพิ่ม
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างทีม "$teamName" สำเร็จ!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ถ้ามีจุดลบทีม ให้เพิ่ม box.write('teams', teams); หลัง setState เช่นกัน

  // เพิ่มฟังก์ชันสำหรับแสดง dialog ยืนยันก่อนออก
  Future<bool> _showExitConfirmation() async {
    if (teams.isEmpty) {
      return true; // ถ้าไม่มีทีมให้ออกได้เลย
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการเสร็จสิ้น'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('คุณได้สร้างทีมทั้งหมด ${teams.length} ทีม'),
            const SizedBox(height: 8),
            const Text('ต้องการกลับไปหน้าหลักหรือไม่?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('เสร็จสิ้น'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedPokemonData = pokemons
        .where((p) => selectedPokemons.contains(p['id']))
        .toList();

    // ฟิลเตอร์โปเกม่อนตามประเภทและค้นหา
    final filteredPokemons = (selectedType == null
            ? pokemons
            : pokemons.where((p) => (p['types'] as List).contains(selectedType)))
        .where((p) =>
            p['name'].toString().toLowerCase().contains(searchText.toLowerCase()))
        .toList();

    return WillPopScope(
      onWillPop: () async {
        if (teams.isNotEmpty) {
          final shouldExit = await _showExitConfirmation();
          if (shouldExit) {
            Navigator.pop(context, teams);
            return false;
          }
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Column(
            children: [
              if (selectedPokemons.isEmpty)
                Text(
                  teams.isEmpty
                      ? 'เลือกโปเกม่อนของคุณ'
                      : 'สร้างทีมแล้ว ${teams.length} ทีม',
                  style: const TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              if (selectedPokemons.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: selectedPokemonData.map((pokemon) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Chip(
                        avatar: CircleAvatar(
                          backgroundImage: NetworkImage(pokemon['image']),
                          backgroundColor: Colors.grey.shade200,
                        ),
                        label: Text(
                          pokemon['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        backgroundColor: Colors.red.shade50,
                        deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red),
                        onDeleted: () {
                          setState(() {
                            selectedPokemons.remove(pokemon['id']);
                          });
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                    )).toList(),
                  ),
                ),
            ],
          ),
          actions: [
            if (selectedPokemons.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.red),
                tooltip: 'Reset Selection',
                onPressed: resetSelection,
              ),
            if (teams.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                tooltip: 'เสร็จสิ้น',
                onPressed: () async {
                  final shouldExit = await _showExitConfirmation();
                  if (shouldExit) {
                    Navigator.pop(context, teams);
                  }
                },
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.shade50,
                Colors.white,
              ],
            ),
          ),
          child: pokemons.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Colors.red))
              : Column(
                  children: [
                    // --- เพิ่ม Search Bar ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'ค้นหาโปเกม่อน...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.red.shade100),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.red.shade100),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                      ),
                    ),
                    // --- จบ Search Bar ---
                    // แสดงสถานะการกรอง
                    if (selectedType != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getTypeIcon(selectedType!), 
                                 color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'กรองแล้ว: $selectedType',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => selectedType = null),
                              child: const Icon(Icons.close, 
                                               color: Colors.red, size: 16),
                            ),
                          ],
                        ),
                      ),
                    // แสดงรายการทีมที่สร้างแล้ว
                    if (teams.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.group, color: Colors.green, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'ทีมที่สร้างแล้ว (${teams.length})',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: teams.map((team) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${team['name']} (${(team['pokemons'] as List).length})',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )).toList(),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GridView.builder(
                          itemCount: filteredPokemons.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final pokemon = filteredPokemons[index];
                            final isSelected = selectedPokemons.contains(pokemon['id']);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedPokemons.remove(pokemon['id']);
                                  } else if (selectedPokemons.length < 3) {
                                    selectedPokemons.add(pokemon['id']);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('เลือกได้สูงสุด 3 ตัวเท่านั้น'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.red.shade100 : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? Colors.red : Colors.grey.shade300,
                                    width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? Colors.red.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.08),
                                      blurRadius: isSelected ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.12),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              pokemon['image'],
                                              height: 70,
                                              width: 70,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => Container(
                                                color: Colors.grey[300],
                                                height: 70,
                                                width: 70,
                                                child: const Icon(Icons.error, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          pokemon['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSelected ? Colors.red : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 2,
                                          runSpacing: 2,
                                          children: (pokemon['types'] as List<String>)
                                              .map((type) => Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: isSelected
                                                          ? Colors.red.withOpacity(0.2)
                                                          : Colors.grey.shade200,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      type,
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        color: isSelected
                                                            ? Colors.red.shade700
                                                            : Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 3,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: Transform.scale(
                                          scale: 0.8,
                                          child: Checkbox(
                                            value: isSelected,
                                            activeColor: Colors.red,
                                            checkColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            onChanged: (bool? value) {
                                              setState(() {
                                                if (value == true && selectedPokemons.length < 3) {
                                                  selectedPokemons.add(pokemon['id']);
                                                } else if (value == false) {
                                                  selectedPokemons.remove(pokemon['id']);
                                                } else if (value == true && selectedPokemons.length >= 3) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('เลือกได้สูงสุด 3 ตัวเท่านั้น'),
                                                      backgroundColor: Colors.orange,
                                                    ),
                                                  );
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedPokemons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FloatingActionButton.extended(
                    heroTag: 'create-team-fab',
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.group_add, color: Colors.white),
                    label: Text(
                      'สร้างทีม (${selectedPokemons.length}/3)',
                      style: const TextStyle(color: Colors.white),
                    ),
                    onPressed: selectedPokemons.isNotEmpty ? _showCreateTeamDialog : null,
                  ),
                ),
              FloatingActionButton(
                heroTag: 'filter-fab',
                backgroundColor: Colors.red,
                child: Icon(
                  selectedType != null ? Icons.filter_alt : Icons.filter_alt_outlined,
                  color: Colors.white,
                ),
                onPressed: () => _showFilterMenu(context),
                tooltip: 'กรองตามประเภท',
              ),
            ],
          ),
        ),
      ),
    );
  }
}