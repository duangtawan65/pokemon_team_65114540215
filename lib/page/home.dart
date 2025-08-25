import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart'; // เพิ่มบรรทัดนี้
import 'package:myapp/page/playerselection.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> teams = [];
  final box = GetStorage(); // เพิ่มบรรทัดนี้

  @override
  void initState() {
    super.initState();
    // โหลด teams จาก storage
    final savedTeams = box.read<List>('teams');
    if (savedTeams != null) {
      teams = List<Map<String, dynamic>>.from(savedTeams);
    }
  }

  Future<void> _openPlayerSelection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Playerselection()),
    );
    
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        // เพิ่มทีมใหม่เข้ากับทีมเดิม (ถ้ามี)
        teams.addAll(result);
        box.write('teams', teams); // เพิ่มบรรทัดนี้
      });
      
      // แสดงข้อความยืนยัน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ได้รับทีมใหม่ ${result.length} ทีม!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _editTeamName(int index) {
    String currentName = teams[index]['name'];
    String newName = currentName;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('แก้ไขชื่อทีม'),
        content: TextField(
          controller: TextEditingController(text: currentName),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'ชื่อทีมใหม่',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit),
          ),
          onChanged: (value) => newName = value,
          onSubmitted: (value) {
            newName = value;
            if (newName.trim().isNotEmpty && newName.trim() != currentName) {
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
              if (newName.trim().isNotEmpty && newName.trim() != currentName) {
                Navigator.pop(context, true);
              } else if (newName.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('กรุณาใส่ชื่อทีม'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } else {
                Navigator.pop(context, false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('บันทึก'),
          ),
        ],
      ),
    ).then((result) {
      if (result == true && newName.trim().isNotEmpty && newName.trim() != currentName) {
        setState(() {
          teams[index]['name'] = newName.trim();
          // อัพเดท timestamp ถ้ามี
          teams[index]['updatedAt'] = DateTime.now().toIso8601String();
          box.write('teams', teams); // เพิ่มบรรทัดนี้
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เปลี่ยนชื่อทีมเป็น "$newName" แล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _deleteTeam(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบทีม "${teams[index]['name']}" หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                teams.removeAt(index);
                box.write('teams', teams); // เพิ่มบรรทัดนี้
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบทีมแล้ว'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _clearAllTeams() {
    if (teams.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบทั้งหมด'),
        content: Text('ต้องการลบทีมทั้งหมด ${teams.length} ทีม หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                teams.clear();
                box.write('teams', teams); // เพิ่มบรรทัดนี้
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ลบทีมทั้งหมดแล้ว'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบทั้งหมด'),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(Map<String, dynamic> team, int index) {
    final pokemons = team['pokemons'] as List<dynamic>;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.purple.withOpacity(0.1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header ของทีม
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _editTeamName(index),
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              team['name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.indigo.withOpacity(0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${pokemons.length} สมาชิก',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editTeamName(index);
                          break;
                        case 'delete':
                          _deleteTeam(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 18),
                            SizedBox(width: 8),
                            Text('แก้ไขชื่อ'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('ลบทีม'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // แสดงรูป Pokemon ในทีม
              if (pokemons.isNotEmpty)
                Container(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: pokemons.length,
                    itemBuilder: (context, pokemonIndex) {
                      final pokemon = pokemons[pokemonIndex];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  pokemon['image'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error, size: 20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 58,
                              child: Text(
                                pokemon['name'],
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              
              const SizedBox(height: 8),
              
              // แสดงวันที่สร้าง (ถ้ามี)
              if (team['createdAt'] != null)
                Text(
                  'สร้างเมื่อ: ${_formatDate(team['createdAt'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'ไม่ทราบ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (teams.isNotEmpty)
            IconButton(
              onPressed: _clearAllTeams,
              icon: const Icon(Icons.clear_all),
              tooltip: 'ลบทีมทั้งหมด',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade50,
              Colors.white,
            ],
          ),
        ),
        child: teams.isEmpty
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'ยังไม่มีทีมที่สร้าง',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'กดปุ่มด้านล่างเพื่อเริ่มสร้างทีม',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  // Header แสดงจำนวนทีม
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.group, color: Colors.white, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ทีมทั้งหมด',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                '${teams.length} ทีม',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${teams.fold(0, (sum, team) => sum + (team['pokemons'] as List).length)} Pokemon',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // รายการทีม
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: teams.length,
                      itemBuilder: (context, index) => _buildTeamCard(teams[index], index),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-team-fab',
        onPressed: _openPlayerSelection,
        tooltip: 'สร้างทีม',
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: Image.asset(
          'assets/images/mental-health (1).png',
          width: 24,
          height: 24,
        ),
        label: const Text('สร้างทีม'),
      ),
    );
  }
}