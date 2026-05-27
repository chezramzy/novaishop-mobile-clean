create unique index if not exists partner_applications_one_visible_request_per_user_idx
  on public.partner_applications(applicant_user_id)
  where applicant_user_id is not null
    and status in ('new', 'reviewing', 'approved', 'rejected');

create policy "app can read partner application status by applicant id"
  on public.partner_applications for select
  to anon, authenticated
  using (applicant_user_id is not null);
