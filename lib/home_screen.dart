                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      Icons.settings_outlined,
                      'Settings',
                      false,
                      () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                    _buildNavItem(Icons.home_rounded, 'Home', true, () {}),
                    _buildNavItem(Icons.trending_up_outlined, 'Trends', false, () {
                      Navigator.pushNamed(context, '/trends');
                    }),
                    _buildNavItem(Icons.history_outlined, 'History', false, () {
                      Navigator.pushNamed(context, '/history');
                    }),
                  ],
                ), 