select * from albums;
select * from employee;
select * from artist;
select * from customer;
select * from genre;
select * from invoice;
select * from invoice_line;
select * from media_type;
select * from playlist;
select * from playlist_track;
select * from track;



-- Q1) : Who is the senior most employee based on job title ?

select * from employee
order by levels desc
limit 1;                             -- ans . Adams Andrew is the senior most employee

-- Q2) : Which countries have the most invoices?
select count(*) as most_invoice ,billing_country from invoice
group by billing_country
order by most_invoice desc;         -- ans . So the most incoives counts are in USA

-- Q3) : What are the top 3 values of total invoice?
select total from invoice
order by total desc
limit 3;                            -- ans . Here are the top 3 incoices

/* Q4) : Which city has the best cutomers ? We would like to throw
a promotional Music Festival in the city we made money. Write a query
that returns one city that has the highest sum of invoice totals.
Return both the city name and sum of all invoice totals? */

select sum(total) as invoice_total, billing_city from  invoice
group by billing_city
order by invoice_total desc;                 -- ans . Here are the cities which has the highest sum of invoice totals.

/* Q5) : Who is the best customer? The customer who has spent the most 
money will declared the best customer. Write a query that return the person who has spent the most money? */

select c.customer_id , c.first_name , c.last_name ,sum(i.total) as most_money 
from customer c 
join invoice i 
on c.customer_id = i.customer_id
group by c.customer_id , c.first_name , c.last_name 
order by most_money desc
limit 1 ;


/* Q6) : Write query to return the email, first name , last name & genre of all rock music listeners. 
Return your list ordered alphabetically by email starting with A .*/

select distinct c.email , c.first_name , c.last_name , g.genre_id 
from genre g
join track t on g.genre_id = t.genre_id
join invoice_line il on t.track_id = il.track_id
join invoice i on il.invoice_id = i.invoice_id
join customer c on c.customer_id = i.customer_id
where g.name like 'Rock'
order by email;


/* Q7) : Let's invite the artists who have written the most rock music in our dataset .
Write a query that returns the artist name and total track of the top 10 rock bands. */

select * from track;
select * from artist;	
select a.artist_id , a.name ,count(a.artist_id) as number_of_songs 
from artist a
join album2 al on a.artist_id = al.artist_id
join track t on al.album_id = t.album_id
join genre g on t.genre_id = g.genre_id
where g.name like 'Rock'
group by a.artist_id, a.name
order by number_of_songs desc
limit 10;


/* Q8) : Return all the track names that have a song length longer than the average
song length. Return the name and milliseconds for each track . order by the song length
with the longest songs listed first. */

select * from track;
select name , milliseconds
from track
where milliseconds > (
	select avg(milliseconds) as avg__track_length
    from track)
order by milliseconds desc;


/* Q9) : Find how much amount spent by each customer on artists? Write a query 
to return customer name, artist name and total spent. */
select * from customer;
select * from artist;

with best_selling_artist as (
	select a.artist_id as artist_id, a.name as artist_name ,
    sum(il.unit_price * il.quantity) as total_sale
    from invoice_line il
    join track t on il.track_id = t.track_id
    join albums al on t.album_id = al.album_id
    join artist a on al.artist_id = a.artist_id
    group by 1
    order by 3 desc
    limit 1
)
select c.customer_id , c.first_name , c.last_name ,bsa.artist_name,
bsa.total_sale as amount_spent
from invoice i 
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join albums al on al.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = al.artist_id
group by 1,2,3,4
order by 5 desc;    



/* Q10) : We want to find out the most popular music genre for each 
country . We determine the most popular genre as the genre with the highest amount of purchases.
write a query that returns each country along with the top genre. For countries where 
the maximum number of purchases is shared return all genres. */

with popular_genre as
(
	select count(il.quantity) as purchase , c.country , g.name , g.genre_id,
    row_number() over(partition by c.country order by count(il.quantity) desc) as RowNo
    from invoice_line il
    join invoice i on i.invoice_id = il.invoice_id
    join customer c on c.customer_id = i.customer_id
    join track t on t.track_id = il.track_id
    join genre g on g.genre_id = t.genre_id
    group by 2,3,4
    order by 2 asc, 1 desc
)
select * from popular_genre where RowNo <= 1;

-- or 

with recursive
	sales_per_country as(
		select count(*) as purchase_per_genre, c.country , g.name , g.genre_id
        from invoice_line il 
        join invoice i on i.invoice_id = il.invoice_id
        join customer c on c.customer_id = i.customer_id
        join track t on t.track_id = il.track_id
        join genre g on g.genre_id = t.genre_id
        group by 2,3,4
        order by 2
	),
    max_genre_per_country as (
		select max(purchase_per_genre) as max_genre_number , country
        from sales_per_country
        group by 2
        order by 2)
        
select sales_per_country.*
from sales_per_country
join max_genre_per_country on sales_per_country.country = max_genre_per_country.country
where sales_per_country.purchase_per_genre = max_genre_per_country.max_genre_number;


/* Q11) : Write a query that determines the customer that has spent the most 
on music for each country. write a query that returns the country along
with the top customer and how much they spent. for countries where the top amount spent is shared,
provide all customers who spent this amount. */

with recursive
	customer_with_country as (
			select c.customer_id, first_name , last_name , billing_country , sum(total) as total_spending
            from invoice i
            join customer c on c.customer_id = i.customer_id
            group by 1,2,3,4
            order by 2,3 desc),
            
		customer_max_spending as (
			select billing_country, max(total_spending) as max_spending
            from customer_with_country
            group by billing_country)
            
		select cc.billing_country , cc.total_spending , cc.first_name , cc.last_name , cc.customer_id
        from customer_with_country cc
        join customer_max_spending ms
        on cc.billing_country = ms.billing_country
        where cc.total_spending = ms.max_spending
        order by 1;
        
        
-- or

with customer_with_country as (
	select c.customer_id , first_name , last_name , billing_country , sum(total) as total_spending ,
    row_number() over(partition by billing_country order by sum(total) desc) as RowNo
    from invoice i
    join customer c on c.customer_id = i.customer_id
    group by 1,2,3,4
    order by 4 asc , 5 desc)
select * from customer_with_country where RowNo <= 1;



-- Thank You 



