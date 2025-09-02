import 'package:anket/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignUpSuccessful extends StatelessWidget {
  const SignUpSuccessful({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/svgs/sign_up_successful.svg'),
            SizedBox(height: 40),
            Text(
              'Kayıt Başarıyla Tamamlandı',
              style: TextStyle(
                color: AppColors.onSurfaceColor,
                fontWeight: FontWeight.w500,
                fontSize: 25,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Her Şey Yolunda...',
              style: TextStyle(
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: CupertinoButton(
                  color: AppColors.successColor,
                  borderRadius: BorderRadius.circular(16),
                  onPressed:
                      () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text(
                    'Tamam',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
