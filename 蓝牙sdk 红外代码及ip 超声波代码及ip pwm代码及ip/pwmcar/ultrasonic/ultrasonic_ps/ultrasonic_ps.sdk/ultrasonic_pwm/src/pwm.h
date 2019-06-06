
#ifndef PWM_H_
#define PWM_H_

void update_freq(const double *fre0, const double *fre1);
void update_speed(const double *wav0, const double *wav1);
void update_mode(const int mode);

void car_start_up(double *wav0, double *wav1);
void car_pull_over(double *wav0, double *wav1);
void car_back_up(double *wav0, double *wav1);
void car_turn_left(double *wav0, double *wav1);
void car_turn_right(double *wav0, double *wav1);
void car_turn_around(double *wav0, double *wav1);
void car_shut_down(double *wav0, double *wav1);


#endif /* PWM_H_ */
