-- 1. Abonentlərin yaş qrupuna görə və cinsiyyətə görə bölgüsünü göstər:
--    Yaş qrupları aşağıdakı şəkildədi
--    18 və aşağı
--    19-30
--    31-50
--    51 və yuxarı
--    Ekrana yaş aralığı,cins və say haqqında informasiyalar çıxsın.
select 
    case
        when trunc(months_between(sysdate,birth_date)/12) <= 18 then '18 və aşağı'
        when trunc(months_between(sysdate,birth_date)/12) between 19 and 30 then '19-30'
        when trunc(months_between(sysdate,birth_date)/12) between 31 and 50 then '31-50'
        else '51 və yuxarı'
   end as "Yaş aralığı",
    gender as "Cins",
    count(*) as "Say"
from subscribers
group by 
    case
       when trunc(months_between(sysdate,birth_date)/12) <= 18 then '18 və aşağı'
       when trunc(months_between(sysdate,birth_date)/12) between 19 and 30 then '19-30'
       when trunc(months_between(sysdate,birth_date)/12) between 31 and 50 then '31-50'
       else '51 və yuxarı'
    end,
    gender
order by "Yaş aralığı";

---Cins üzrə həmin yaş qrupuna düşən abonentlərin sayı
select * from (select gender "Cins",
           case
               when trunc(months_between(sysdate,birth_date)/12) <= 18 then '18 və aşağı'
               when trunc(months_between(sysdate,birth_date)/12) between 19 and 30 then '19-30'
               when trunc(months_between(sysdate,birth_date)/12) between 31 and 50 then '31-50'
               else '51 və yuxarı'
           end as "Yaş aralığı"
    from subscribers
)
pivot (count(*) 
       for "Yaş aralığı" in (
        '18 və aşağı' as "18 və aşağı",
        '19-30' as "19-30",
        '31-50' as "31-50",
        '51 və yuxarı' as "51 və yuxarı" ))
order by 1;

-- Yaş qrupu üzrə kişi qadın sayı
select * from ( select gender "Cins",
           case
               when trunc(months_between(sysdate,birth_date)/12) <= 18 then '18 və aşağı'
               when trunc(months_between(sysdate,birth_date)/12) between 19 and 30 then '19-30'
               when trunc(months_between(sysdate,birth_date)/12) between 31 and 50 then '31-50'
               else '51 və yuxarı'
           end as "Yaş aralığı"
    from subscribers)
pivot (count(*) for "Cins" in ('Male' as "Kişi",'Female' as "Qadın"))
order by "Yaş aralığı";

--2.Hər abonent üçün son ödəniş tarixini və məbləğini göstər: 
--    Ekrana Ad, soyad, son ödəniş tarixi, məbləği və ödənişin üsulu haqqında informasiyalar çıxsın.         
select "Abonentin adı",
       "Abonentin soyadı",
       "Son ödəniş tarixi",
       "Son ödəniş məbləği",
       "Son ödəniş üsulu" 
from(
    select sub.name as  "Abonentin adı",
           sub.surname  as "Abonentin soyadı",
           p.payment_date as "Son ödəniş tarixi",
           p.amount as "Son ödəniş məbləği",
           pt.name as "Son ödəniş üsulu",
           row_number() over(partition by sub.subscribers_id order by p.payment_date desc) as rn
     from subscribers sub 
     join payments p
        on sub.subscribers_id = p.subscribers_id
     join payment_method_type pt
        on p.payment_type_id = pt.payment_type_id)
where rn = 1;


-- 3.Aktiv xidmətlər üzrə abonentlərin sayını və ümumi ödəniş məbləğini göstər:
--    Ekrana xidmətin adı,abonentlərin sayını və ümumi ödəniş məbləği haqqında informasiyalar çıxsın. 
with servis as (select distinct caller_id as subscribers_id,service_id 
                        from calls 
                 union
                 select distinct sender_id as subscribers_id,service_id
                        from sms_informations)
                        
select srv.service_name as "Xidmət adı",
       count( distinct ser.subscribers_id) as "Abonent sayı",
       sum(p.amount) as "Ümumi ödəniş"
from services srv
join servis ser
    on srv.service_id = ser.service_id
join payments p
   on ser.subscribers_id=p.subscribers_id
where srv.deactivation_date is null
group by srv.service_name
order by srv.service_name;

-- 4.Hər abonent üçün edilən zənglərin sayını və ümumi zəng müddətini göstər:
--    Ekrana ad, soyad, abonent üçün edilən zənglərin sayını, ümumi zəng müddətini, zəngin tipi haqqında informasiyalar çıxsın.
select sub.name as "Ad",
       sub.surname as "Soyad",
       count(c.call_id) as "Zəng sayı",
       sum(nvl(c.call_duration,0)) as "Ümumi zəng müddəti(saniyə)",
       c.call_type as "Zəngin tipi"
from subscribers sub
join calls c 
    on c.caller_id= sub.subscribers_id
group by sub.name, sub.surname, c.call_type

union all

select sub.name as "Ad",
       sub.surname as "Soyad",
       count(c.call_id) as "Zəng sayı",
       sum(nvl(c.call_duration,0)) as "Ümumi zəng müddəti(saniyə)",
       null as "Zəng tipi"
from subscribers sub
join calls c 
    on c.caller_id= sub.subscribers_id
group by sub.name, sub.surname
order by "Ad","Soyad";


--5.Hər abonent üçün tarifə görə aylıq ödədikləri məbləği və zənglərin sayını göstər:
--    Ekrana ad, soyad,tarifə görə aylıq ödədikləri məbləğ və zənglərin sayı haqqında informasiyalar çıxsın. 
with abonent_services as (select caller_id as subscribers_id,service_id 
                                 from calls
                          union 
                          select sender_id as subscribers_id,service_id
                                 from sms_informations),
abonent_tariff as (select  distinct a_ser.subscribers_id,
                          t.tariff_id,
                          t.tariff_name,
                          t.monthly_subscription
                  from abonent_services a_ser
                  join services srv
                    on a_ser.service_id=srv.service_id
                  join tariff_informations t
                    on srv.tariff_id=t.tariff_id),
zənglərin_sayı as (select caller_id, count(*) as say
                      from calls
                    group by caller_id)           
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       at.tariff_name "Tarifin adı",
       nvl(at.monthly_subscription,0) "Aylıq ödəniş",
       nvl(zs.say,0) "Zəng sayı"
from subscribers sub
left join abonent_tariff at 
  on  sub.subscribers_id=at.subscribers_id
left join zənglərin_sayı zs
    on zs.caller_id= at.subscribers_id
order by sub.name, sub.surname;


--6.Zənglərin növünə görə abonentlərin sayını və ümumi zəng müddətini göstər:
select
    ct.name as "Zəng növü",
    count( distinct c.caller_id) as "Abonent sayı",
    sum(c.call_duration) as "Ümumi zəng müddəti(saniyə)"
from call_type ct 
join calls c on ct.call_type_id=c.call_type_id
group by ct.name
order by ct.name;

--7.Hər tarif üzrə abonentlərin orta yaşını göstər
with abonent_servis as (
    select caller_id as subscribers_id, service_id
      from calls
    union
    select sender_id as subscribers_id, service_id
      from sms_informations),

abonent_tariff as (
    select distinct a_ser.subscribers_id,
           t.tariff_id,
           t.tariff_name
      from abonent_servis a_ser
      join services srv
        on a_ser.service_id = srv.service_id
      join tariff_informations t
        on srv.tariff_id = t.tariff_id)

select at.tariff_id  "Tarif ID",
       at.tariff_name "Tarifin adı",
       round(avg(months_between(sysdate, sub.birth_date)/12)) "Orta yaş"
from subscribers sub
join abonent_tariff at
  on at.subscribers_id = sub.subscribers_id
group by at.tariff_id, at.tariff_name
order by at.tariff_id;
            
--8.Son 6 ayda edilən ödənişlərin məbləğini və xidmətlərin sayını abonentlər üzrə göstər.
--    Ekrana abonentin adı, abonentin soyadı, xidmətlərin sayı və 6 ayda edilən ödənişlərin məbləği haqqında informasiyalar çıxsın.

---Əgər 6ay sadece ödənişlərin məbləğinə aiddirsə:
with abonent_services as (select caller_id as subscribers_id,service_id 
                                 from calls
                          union 
                          select sender_id as subscribers_id,service_id
                                 from sms_informations)
                                 
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       count( distinct a_ser.service_id) "Xidmətlərin sayı",
       nvl(sum(p.amount),0) "Ödənişlərin məbləği"
from subscribers sub
join abonent_services a_ser 
  on sub.subscribers_id=a_ser.subscribers_id
join payments p
  on sub.subscribers_id=p.subscribers_id
     and  p.payment_date >=add_months(sysdate,-6)
group by sub.name,sub.surname
order by sub.name,sub.surname;

--Əgər 6 ay həm xidmət sayına,həm də ödənişlərin məbləğinə aiddirsə;
with abonent_services as (select caller_id as subscribers_id,service_id 
                                 from calls
                          union 
                          select sender_id as subscribers_id,service_id
                                 from sms_informations)
                                 
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       count( distinct a_ser.service_id) "Xidmətlərin sayı",
       nvl(sum(p.amount),0) "Ödənişlərin məbləği"
from subscribers sub
join abonent_services a_ser 
  on sub.subscribers_id=a_ser.subscribers_id
join payments p
  on sub.subscribers_id=p.subscribers_id
where p.payment_date >=add_months(sysdate,-6)
group by sub.name,sub.surname
order by sub.name,sub.surname;
      
--9.Hər şikayət növü üzrə həll olunma müddətinin orta dəyərini və şikayət sayını göstər:
select cs.complaint_type_id "Şikayət növü",
       ct.complaint_type_name "Şikayət növünün adı",
       avg(cs.resolution_date - cs.submission_date) "Həll olunma müddəti(günlə)",
       count(cs.complaint_id) "Şikayət sayı"
from complaints_and_support_requests cs
join complaint_type ct
    on cs.complaint_type_id = ct.complaint_type_id
where cs.resolution_date is not null
group by cs.complaint_type_id,ct.complaint_type_name
order by cs.complaint_type_id,ct.complaint_type_name;

--10. Hər abonent üçün son 12 ayda göndərilən SMS-lərin sayını və SMS məzmununu göstər:
select sub.subscribers_id "Abonent ID",
       sub.name "Abonentin adı",
       sub.surname  "Abonentin soyadı",
       count(sms.sms_id) "SMS sayı",
       listagg(sms.sms_content,'/') within group(order by sms.sms_id) "SMS məzmunu" --sms_date ilə sıralayanda mətn məzmununun sırası pozulurdu ona görə sms_id ile etdim
from subscribers sub
left join sms_informations sms
    on sub.subscribers_id = sms.sender_id 
      and sms_date >= add_months(sysdate,-12)
group by sub.subscribers_id,
         sub.name,
         sub.surname
order by subscribers_id;

--11.Hər abonent üçün edilən zənglərin ümumi müddətini və ödəniş məlumatlarını göstər:    
--   Ekrana abonentin adı, abonentin soyadı, zənglərin ümumi müddətini ödəniş məlumatları haqqında informasiyalar çıxsın. 

--Əgər bütün ödəniş məlumatları istənilirsə:
with abonent_calls as (select caller_id,sum(call_duration) as total_duration 
                       from calls
                       group by caller_id)
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       nvl(ac.total_duration,0) as "Zənglərin ümumi müddəti(saniyə)",
       p.payment_id "Ödəniş ID",
       p.amount "Ödəniş məbləği",
       p.payment_date "Ödəniş tarixi",
       p.payment_type_id "Ödəniş üsulu ID",
       pt.name "Ödəniş üsulunun adı"
from subscribers sub
left join abonent_calls ac
       on ac.caller_id = sub.subscribers_id
left join payments p
       on p.subscribers_id = sub.subscribers_id
left join payment_method_type pt
      on pt.payment_type_id = p.payment_type_id
order by sub.name, sub.surname,p.payment_type_id;


-- Ödəniş məlumatları dedikdə sadəcə ümumi ödəniş məbləği nəzərdə tutulursa;
with abonent_calls as (select caller_id,sum(call_duration) as total_duration 
                       from calls
                       group by caller_id),
abonent_payments as ( select subscribers_id,sum(amount) as total_payment,count(payment_id) as payment_count
                      from payments
                      group by subscribers_id)
                      
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       nvl(ac.total_duration,0) as "Zənglərin ümumi müddəti",
       nvl(ap.total_payment,0) as "Ümumi ödəniş",
       nvl(ap.payment_count,0) as "Ümumi ödəniş sayi"
from subscribers sub 
left join abonent_calls ac on sub.subscribers_id=ac.caller_id
left join abonent_payments ap on sub.subscribers_id = ap.subscribers_id;
      
--12. Hər tarif üzrə abonentlərin aylıq ödədikləri məbləğin orta dəyərini və zənglərin sayını göstər:
--   Ekrana tarif adı, abonentlərin aylıq ödədikləri məbləğin orta dəyəri və zənglərin sayı haqqında informasiyalar çıxsın. 

with abonent_servisleri as (select caller_id as subscribers_id,
                                   service_id,
                                   trunc(call_date,'mm') as ay
                            from calls
                              union
                            select sender_id as subscribers_id,
                                    service_id,
                                    trunc(sms_date,'mm') as ay
                            from sms_informations),
                            
abonent_tariff as (select distinct a_ser.subscribers_id,
                          t.tariff_id,
                          t.tariff_name,
                          a_ser.ay
                  from abonent_servisleri a_ser
                  join services srv 
                      on a_ser.service_id=srv.service_id
                  join tariff_informations t
                      on t.tariff_id=srv.tariff_id),       
                      
abonent_calls as (select caller_id as subscribers_id,
                         trunc(call_date,'mm') as ay,
                         count(*) as call_count
                    from calls
                    group by caller_id,trunc(call_date,'mm')),
                    
abonent_payments as (select subscribers_id,
                            trunc(payment_date,'mm') as ay,
                            sum(amount) as total_payment
                     from payments 
                     group by subscribers_id, trunc(payment_date,'mm'))

select at.tariff_name "Tarifin adı",
      round(avg(nvl(ap.total_payment,0)),2) "Aylıq orta məbləğ",
      sum(ac.call_count) "Ümumi zənglərin sayı"
from abonent_tariff at
left join abonent_payments ap 
  on at.subscribers_id=ap.subscribers_id and at.ay = ap.ay
left join abonent_calls ac
  on at.subscribers_id=ac.subscribers_id and at.ay = ac.ay
group by at.tariff_name
order by at.tariff_name;
--13. Hər abonent üçün son 12 ayda göndərilən SMS-lərin məzmununu və göndərilən SMS növlərini göstər:
--   Ekrana abonentin adı, soyadı, son 12 ayda göndərilən SMS-lərin məzmununu və göndərilən SMS növləri haqqında informasiyalar çıxsın.
select sub.name as "Abonentin adı",sub.surname as "Abonentin soyadı",
       listagg(sms.sms_content,chr(10)) within group(order by sms.sms_id) "SMS məzmunu",--sms_date ilə sıralayanda mətn məzmununun sırası pozulurdu ona görə sms_id ile etdim
       smt.name as "SMS növu" --1 növdən istifadə etdiyinə görə listaggla yazmadım
from subscribers sub 
left join sms_informations sms 
  on sub.subscribers_id = sms.sender_id 
     and  sms_date >= add_months(sysdate,-12)
left join sms_types smt 
on sms.sms_type_id=smt.sms_type_id
     and  sms_date >= add_months(sysdate,-12)
group by sub.name,sub.surname,smt.name
order by sub.name, sub.surname;
      
-- 14. Hər abonent üçün son 6 ayda edilən ödənişlərin məbləğini və xidmətlərin sayını göstər:
--   Ekrana abonentin adı, soyadı, son 6 ayda edilən ödənişlərin məbləğini və xidmətlərin sayı haqqında informasiyalar çıxsın.
with abonent_services as (select caller_id as subscribers_id,service_id 
                                 from calls
                          union 
                          select sender_id as subscribers_id,service_id
                                 from sms_informations)
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       nvl(sum(p.amount),0) "Ödənişlərin məbləği",
       count( distinct a_ser.service_id) "Xidmətlərin sayı"
from subscribers sub
left join abonent_services a_ser 
  on sub.subscribers_id=a_ser.subscribers_id
left join payments p
  on sub.subscribers_id=p.subscribers_id
where p.payment_date >=add_months(sysdate,-6)
group by sub.name,sub.surname
order by sub.name,sub.surname;

-- 15. Hər abonent üçün ödənişlər və şikayətlərin məbləğini göstər:
--   Ekrana abonentin adı, soyadı, hər abonent üçün ödənişlər və şikayətlərin sayı haqqında informasiyalar çıxsın.

with abonent_payments as (select subscribers_id,count(payment_id) as payment_count, sum(amount) as total_payment
                             from payments
                             group by subscribers_id),
                     
abonent_complaints as (select subscribers_id, count(*) as complaint_count
                         from complaints_and_support_requests
                        group by subscribers_id)
select sub.name "Abonentin adı",
       sub.surname "Abonentin soyadı",
       NVL(ap.total_payment,0) "Ümumi ödəniş məbləği",
       NVL(ap.payment_count,0) "Ümumi ödəniş sayı",
       NVL(ac.complaint_count,0) "Ümumi şikayət sayı"
from subscribers sub
left join abonent_payments ap
    on sub.subscribers_id = ap.subscribers_id
left join abonent_complaints ac
    on sub.subscribers_id = ac.subscribers_id
order by sub.name, sub.surname;

-- 16. Hər tarif üzrə abonentlərin yaş qruplarına görə və aylıq ödədikləri məbləğin orta dəyərini göstər:
--     Ekrana tarifin adı, yaş qrupları, aylıq ödədikləri məbləğin orta dəyəri haqqında informasiyalar çıxsın.   
with abonent_servis as (select caller_id as subscribers_id,service_id,
                               trunc(call_date,'mm') as ay
                        from calls
                        union
                       select sender_id as subscribers_id, service_id,
                       trunc(sms_date,'mm') as ay
                       from sms_informations),
abonent_tariff as (select distinct a_ser.subscribers_id,
                                   t.tariff_id,
                                   t.tariff_name,
                                   a_ser.ay
                    from abonent_servis a_ser
                    join services srv
                       on a_ser.service_id = srv.service_id
                    join tariff_informations t
                      on srv.tariff_id = t.tariff_id),
yaş_qrupları as (select subscribers_id,
                       case 
                            when trunc(months_between(sysdate,birth_date)/12) <= 18 then '18 və aşağı'
                            when trunc(months_between(sysdate,birth_date)/12) between 19 and 30 then '19-30'
                            when trunc(months_between(sysdate,birth_date)/12) between 31 and 50 then '31-50'
                            else '51 və yuxarı'
                        end as yas_qrupu
                 from subscribers),
abonent_payments as (select subscribers_id,
                             trunc(payment_date,'mm') as ay,
                             sum(amount) as total_payment
                    from payments
                    group by subscribers_id, trunc(payment_date,'mm'))
                    
select at.tariff_name  "Tarifin adı",
       yq.yas_qrupu  "Yaş qrupu",
       round(avg(nvl(ap.total_payment,0)),2) AS "Aylıq orta məbləğ"
from abonent_tariff at
left join abonent_payments ap 
  on at.subscribers_id = ap.subscribers_id
     and at.ay = ap.ay
left join yaş_qrupları yq
  on at.subscribers_id = yq.subscribers_id
group by at.tariff_name, yq.yas_qrupu
order by at.tariff_name;

       
-- 17. Hər abonentin ümumi ödədiyi məbləği və onların ödədikləri məbləğin tariflərin ortalama ödəmə məbləğindən yüksək olub 
--     olmadığını göstərən sorğu:
with abonent_servis as (select caller_id as subscribers_id,service_id
                        from calls
                        union 
                        select sender_id as subscribers_id,service_id
                        from sms_informations),
abonent_tariff as (select distinct a_ser.subscribers_id,
                                   t.tariff_id,
                                   t.tariff_name
                    from abonent_servis a_ser
                    join services srv 
                      on a_ser.service_id=srv.service_id
                    join tariff_informations t
                      on t.tariff_id=srv.tariff_id),
abonent_total_payment as (select subscribers_id,
                                sum(amount) as total_payment
                         from payments
                         group by subscribers_id)
                         
select sub.name " Abonentin adı",
       sub.surname "Abonentin Soyadı",
       at.tariff_name "Tarifin adı",
       nvl(atp.total_payment,0) "Abonentin ümumi ödənişi",
       round(avg(nvl(atp.total_payment,0)) over(partition by at.tariff_id),2) "Tariflərin ortalama ödənişi",
       case
         when nvl(atp.total_payment,0) >  avg(nvl(atp.total_payment,0)) over(partition by at.tariff_id)  then 'Yüksəkdir'
         else 'Yüksək deyil'
       end "Ortalama ödəmə məbləğindən yüksəkdir mi?"
from subscribers sub
join abonent_tariff at
  on sub.subscribers_id=at.subscribers_id
left join abonent_total_payment atp
  on sub.subscribers_id=atp.subscribers_id
order by at.tariff_name, sub.name, sub.surname;   



-- 18. Hər abonentin zənglərin ümumi müddətini və onların zəng müddətinin abonentin yaş qrupunun ortalama zəng müddətindən 
--     yüksək olub olmadığını göstərən sorğu:               
 with yas_qrupu as (
    select subscribers_id,
           case
              when trunc(months_between(sysdate,birth_date)/12) <= 18 then '18 və aşağı'
              when trunc(months_between(sysdate,birth_date)/12) between 19 and 30 then '19-30'
              when trunc(months_between(sysdate,birth_date)/12) between 31 and 50 then '31-50'
              else '51 və yuxarı'
           end as yas_qrupu
    from subscribers),
abonent_zeng as (
    select caller_id as subscribers_id,
           sum(call_duration) as total_duration
    from calls
    group by caller_id)

select sub.name " Abonentin adı",
       sub.surname "Abonentin Soyadı",
       yq.yas_qrupu "Yaş qrupu",
       nvl(az.total_duration,0) "Ümumi zəng müddəti",
       avg(nvl(az.total_duration,0)) over(partition by yq.yas_qrupu) "Yaş qrupu üzrə orta müddət",
       case
           when nvl(az.total_duration,0) > avg(nvl(az.total_duration,0)) over(partition by yq.yas_qrupu) then 'Yüksəkdir'
           else 'Yüksək deyil'
       end "Ortalama zəng müddətindən yüksəkdir mi?"
from subscribers sub
left join yas_qrupu yq
  on sub.subscribers_id = yq.subscribers_id
left join abonent_zeng az
  on az.subscribers_id = sub.subscribers_id
order by yq.yas_qrupu, sub.name, sub.surname;
   
      

  
       

