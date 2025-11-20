from collections import defaultdict
import calendar
import csv
import io
import json
from datetime import date, datetime, timedelta

from django.contrib import messages
from django.contrib.auth import get_user_model
from django.contrib.auth.mixins import LoginRequiredMixin
from django.contrib.auth.views import LoginView, LogoutView
from django.db import IntegrityError
from django.db.models import Count, Q, Sum, Prefetch
from django.http import HttpResponse, JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse, reverse_lazy
from django.utils import timezone
from django.views import View
from django.views.generic import (
    RedirectView,
    CreateView,
    DeleteView,
    DetailView,
    FormView,
    ListView,
    TemplateView,
    UpdateView,
)

from .forms import (
    ClasseForm,
    MenuJournalierForm,
    MenuMensuelForm,
    RoleAuthenticationForm,
    StudentFilterForm,
    StudentForm,
    UserProfileForm,
    EleveImportForm,
    PrestataireForm,
)
from .models import (
    AbonnementCantine,
    Classe,
    DepenseCantine,
    Eleve,
    MenuJournalier,
    MenuMensuel,
    PresenceRepas,
    UserProfile,
)


class CustomLoginView(LoginView):
    """Page de connexion stylisée avec redirection selon le rôle."""

    template_name = "cantines/login.html"
    authentication_form = RoleAuthenticationForm
    redirect_authenticated_user = True

    def form_valid(self, form):
        response = super().form_valid(form)
        # S'assurer que le profil existe pour les anciens comptes
        UserProfile.objects.get_or_create(user=self.request.user)

        if self.request.headers.get("x-requested-with") == "XMLHttpRequest":
            return JsonResponse(
                {
                    "status": "success",
                    "redirect_url": self.get_success_url(),
                }
            )

        return response

    def get_success_url(self):
        return reverse("cantine:dashboard_redirect")

    def form_invalid(self, form):
        if self.request.headers.get("x-requested-with") == "XMLHttpRequest":
            non_field_errors = list(form.non_field_errors())
            return JsonResponse(
                {
                    "status": "error",
                    "message": non_field_errors[0]
                    if non_field_errors
                    else "Identifiants incorrects. Merci de réessayer.",
                    "errors": form.errors,
                },
                status=400,
            )
        return super().form_invalid(form)


class ProfileRequiredMixin(LoginRequiredMixin):
    def dispatch(self, request, *args, **kwargs):
        ensure_profile(request.user)
        return super().dispatch(request, *args, **kwargs)


class RoleRequiredMixin(LoginRequiredMixin):
    """Mixin pour restreindre l'accès selon le rôle défini sur le profil."""

    required_role = None

    def dispatch(self, request, *args, **kwargs):
        if not request.user.is_authenticated:
            return self.handle_no_permission()
        profile = ensure_profile(request.user)
        if self.required_role and profile.role != self.required_role:
            messages.error(
                request,
                "Vous n'avez pas les autorisations nécessaires pour accéder à cette page.",
            )
            return redirect("cantine:dashboard_redirect")
        return super().dispatch(request, *args, **kwargs)


class DashboardRedirectView(LoginRequiredMixin, RedirectView):
    """Redirection intelligente vers le tableau de bord du rôle connecté."""

    pattern_name = "cantine:login"

    def get_redirect_url(self, *args, **kwargs):
        profile = getattr(self.request.user, "profile", None)
        if profile is None:
            profile = UserProfile.objects.create(user=self.request.user)
        if profile.role == UserProfile.Role.PRESTATAIRE:
            return reverse("cantine:prestataire_dashboard")
        return reverse("cantine:admin_dashboard")


class AdminDashboardView(RoleRequiredMixin, View):
    """Vue principale de l'application web d'administration."""

    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/admin_dashboard.html"

    def get(self, request):
        context = self._build_context(request)
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("action")

        if action == "create_student":
            return self._handle_student_submission(request)
        if action == "create_classe":
            return self._handle_classe_submission(request)

        messages.error(request, "Action inconnue transmise au tableau de bord.")
        return redirect("cantine:admin_dashboard")

    def _handle_student_submission(self, request):
        student_form = StudentForm(request.POST, request.FILES)
        if student_form.is_valid():
            eleve = student_form.save()
            AbonnementCantine.objects.get_or_create(eleve=eleve)
            messages.success(request, "Élève inscrit avec succès.")
            return redirect("cantine:admin_dashboard")

        messages.error(
            request,
            "Le formulaire d'inscription comporte des erreurs. Merci de vérifier les informations saisies.",
        )
        context = self._build_context(request, student_form=student_form)
        return render(request, self.template_name, context, status=400)

    def _handle_classe_submission(self, request):
        classe_form = ClasseForm(request.POST)
        if classe_form.is_valid():
            classe_form.save()
            messages.success(request, "Classe créée avec succès.")
            return redirect("cantine:admin_dashboard")

        messages.error(request, "Impossible d'enregistrer la classe.")
        context = self._build_context(request, classe_form=classe_form)
        return render(request, self.template_name, context, status=400)

    def _build_context(
        self,
        request,
        student_form=None,
        classe_form=None,
        filter_form=None,
    ):
        base_context = build_dashboard_context()
        student_form = student_form or StudentForm()
        classe_form = classe_form or ClasseForm()
        filter_form = filter_form or StudentFilterForm(request.GET or None)

        students = self._filtered_students(filter_form)
        students_preview = list(students[:5])
        students_total = students.count()

        base_context.update(
            {
                "student_form": student_form,
                "classe_form": classe_form,
                "filter_form": filter_form,
                "students": students_preview,
                "students_total": students_total,
                "students_preview_limit": 5,
                "students_more_url": reverse("cantine:eleve_list"),
                "latest_students": Eleve.objects.select_related("classe").order_by("-date_inscription")[:5],
                "is_admin": True,
            }
        )
        return base_context

    def _filtered_students(self, filter_form):
        queryset = Eleve.objects.select_related("classe").all()

        if filter_form.is_bound and filter_form.is_valid():
            recherche = filter_form.cleaned_data.get("recherche")
            classe = filter_form.cleaned_data.get("classe")
            statut = filter_form.cleaned_data.get("statut")

            if recherche:
                queryset = queryset.filter(
                    Q(nom__icontains=recherche)
                    | Q(prenom__icontains=recherche)
                    | Q(matricule__icontains=recherche)
                )

            if classe:
                queryset = queryset.filter(classe=classe)

            if statut == "actif":
                queryset = queryset.filter(actif=True)
            elif statut == "inactif":
                queryset = queryset.filter(actif=False)

        return queryset


class ClasseListView(RoleRequiredMixin, ListView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/classe_list.html"
    model = Classe
    context_object_name = "classes"
    paginate_by = 20

    def get_queryset(self):
        return Classe.objects.order_by("nom")


class ClasseCreateView(RoleRequiredMixin, CreateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/classe_form.html"
    form_class = ClasseForm
    success_url = reverse_lazy("cantine:classe_list")

    def form_valid(self, form):
        messages.success(self.request, "Classe créée avec succès.")
        return super().form_valid(form)


class ClasseUpdateView(RoleRequiredMixin, UpdateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/classe_form.html"
    form_class = ClasseForm
    model = Classe
    success_url = reverse_lazy("cantine:classe_list")

    def form_valid(self, form):
        messages.success(self.request, "Classe mise à jour avec succès.")
        return super().form_valid(form)


class ClasseDeleteView(RoleRequiredMixin, DeleteView):
    required_role = UserProfile.Role.ADMIN
    model = Classe
    template_name = "cantines/classe_confirm_delete.html"
    success_url = reverse_lazy("cantine:classe_list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Classe supprimée avec succès.")
        return super().delete(request, *args, **kwargs)


class EleveListView(ProfileRequiredMixin, ListView):
    template_name = "cantines/eleve_list.html"
    context_object_name = "eleves"
    model = Eleve
    paginate_by = 12

    def get_queryset(self):
        queryset = (
            Eleve.objects.select_related("classe")
            .order_by("nom", "prenom")
        )
        search = self.request.GET.get("search", "").strip()
        if search:
            queryset = queryset.filter(
                Q(nom__icontains=search)
                | Q(prenom__icontains=search)
                | Q(matricule__icontains=search)
            )
        classe_id = self.request.GET.get("classe")
        if classe_id:
            queryset = queryset.filter(classe_id=classe_id)
        actif = self.request.GET.get("actif")
        if actif == "1":
            queryset = queryset.filter(actif=True)
        elif actif == "0":
            queryset = queryset.filter(actif=False)
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context["classes"] = Classe.objects.order_by("nom")
        context["classe_selected"] = self.request.GET.get("classe", "")
        context["search"] = self.request.GET.get("search", "")
        context["actif_selected"] = self.request.GET.get("actif", "")
        params = self.request.GET.copy()
        view_mode = params.get("view", "list")
        if view_mode not in {"list", "grid"}:
            view_mode = "list"
        for key in ["page"]:
            params.pop(key, None)
        list_params = params.copy()
        grid_params = params.copy()
        list_params["view"] = "list"
        grid_params["view"] = "grid"
        context["view_mode"] = view_mode
        context["list_view_url"] = f"?{list_params.urlencode()}" if list_params else "?view=list"
        context["grid_view_url"] = f"?{grid_params.urlencode()}" if grid_params else "?view=grid"
        return context


class EleveCreateView(RoleRequiredMixin, CreateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/eleve_form.html"
    form_class = StudentForm
    success_url = reverse_lazy("cantine:eleve_list")

    def form_valid(self, form):
        response = super().form_valid(form)
        AbonnementCantine.objects.get_or_create(eleve=self.object)
        messages.success(self.request, "Élève créé avec succès.")
        return response


class EleveUpdateView(RoleRequiredMixin, UpdateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/eleve_form.html"
    form_class = StudentForm
    model = Eleve
    success_url = reverse_lazy("cantine:eleve_list")

    def form_valid(self, form):
        response = super().form_valid(form)
        messages.success(self.request, "Élève mis à jour avec succès.")
        return response


class EleveDeleteView(RoleRequiredMixin, DeleteView):
    required_role = UserProfile.Role.ADMIN
    model = Eleve
    template_name = "cantines/eleve_confirm_delete.html"
    success_url = reverse_lazy("cantine:eleve_list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Élève supprimé avec succès.")
        return super().delete(request, *args, **kwargs)


class EleveDetailView(ProfileRequiredMixin, DetailView):
    model = Eleve
    template_name = "cantines/eleve_detail.html"
    context_object_name = "eleve"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        eleve = self.object
        today = timezone.localdate()
        start_month = today.replace(day=1)
        repas_ce_mois = eleve.presences.filter(date__gte=start_month, present=True).count()
        repas_recents = (
            eleve.presences.filter(present=True)
            .select_related("menu")
            .order_by("-date", "-heure_pointage")[:10]
        )
        inscriptions = []
        abonnement = getattr(eleve, "abonnement", None)
        for i in range(6):
            target = subtract_months(today, i)
            first_day = target.replace(day=1)
            last_day = target.replace(day=calendar.monthrange(target.year, target.month)[1])
            inscrit = eleve.actif
            if abonnement:
                if abonnement.date_debut and first_day < abonnement.date_debut:
                    inscrit = False
                if abonnement.date_fin and last_day > abonnement.date_fin:
                    inscrit = False
            inscriptions.append(
                {
                    "mois": target.strftime("%m"),
                    "annee": target.year,
                    "inscrit": inscrit,
                }
            )
        inscriptions.reverse()
        context.update(
            {
                "repas_ce_mois": repas_ce_mois,
                "repas_recents": repas_recents,
                "inscriptions": inscriptions,
            }
        )
        return context


class EleveImportView(RoleRequiredMixin, FormView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/eleve_import.html"
    form_class = EleveImportForm
    success_url = reverse_lazy("cantine:eleve_list")

    def form_valid(self, form):
        fichier = form.cleaned_data["fichier"]
        decoded = fichier.read().decode("utf-8-sig")
        reader = csv.reader(io.StringIO(decoded))
        created = 0
        updated = 0
        for index, row in enumerate(reader):
            if not row or all(not cell.strip() for cell in row):
                continue
            header_candidate = "".join(row).lower()
            if index == 0 and ("matricule" in header_candidate or "prénom" in header_candidate):
                continue
            try:
                matricule = (row[0] or "").strip() or f"AUTO-{timezone.now().timestamp()}"
                prenom = (row[1] or "").strip()
                nom = (row[2] or "").strip()
            except IndexError:
                continue
            if not prenom or not nom:
                continue
            classe_nom = row[3].strip() if len(row) > 3 else ""
            telephone = row[4].strip() if len(row) > 4 else ""
            email = row[5].strip() if len(row) > 5 else ""
            classe = None
            if classe_nom:
                classe, _ = Classe.objects.get_or_create(nom=classe_nom)
            eleve, created_flag = Eleve.objects.update_or_create(
                matricule=matricule,
                defaults={
                    "prenom": prenom,
                    "nom": nom,
                    "classe": classe,
                    "contact_parent": telephone,
                    "email_parent": email,
                },
            )
            AbonnementCantine.objects.get_or_create(eleve=eleve)
            if created_flag:
                created += 1
            else:
                updated += 1
        messages.success(
            self.request,
            f"Import terminé : {created} élève(s) créés, {updated} mis à jour.",
        )
        return super().form_valid(form)


class EleveExportView(RoleRequiredMixin, View):
    required_role = UserProfile.Role.ADMIN

    def get(self, request, *args, **kwargs):
        response = HttpResponse(content_type="text/csv")
        response["Content-Disposition"] = 'attachment; filename="eleves.csv"'
        writer = csv.writer(response)
        writer.writerow([
            "Matricule",
            "Prénom",
            "Nom",
            "Classe",
            "Téléphone parent",
            "Email parent",
        ])
        for eleve in Eleve.objects.select_related("classe").order_by("nom", "prenom"):
            writer.writerow(
                [
                    eleve.matricule,
                    eleve.prenom,
                    eleve.nom,
                    eleve.classe.nom if eleve.classe else "",
                    eleve.contact_parent,
                    eleve.email_parent,
                ]
            )
        return response


class ElevesInscritsView(RoleRequiredMixin, TemplateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/eleves_inscrits.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        today = timezone.localdate()
        mois = int(self.request.GET.get("mois", today.month))
        annee = int(self.request.GET.get("annee", today.year))
        first_day = date(annee, mois, 1)
        last_day = date(annee, mois, calendar.monthrange(annee, mois)[1])
        eleves = (
            Eleve.objects.filter(actif=True, date_inscription__lte=last_day)
            .select_related("classe")
            .order_by("classe__nom", "nom")
        )
        context.update(
            {
                "eleves": eleves,
                "mois": mois,
                "annee": annee,
            }
        )
        return context


class PrestataireDashboardView(RoleRequiredMixin, View):
    """Interface mobile/web pour la prestataire de la cantine."""

    required_role = UserProfile.Role.PRESTATAIRE
    template_name = "cantines/prestataire_dashboard.html"

    def get(self, request):
        context = self._build_context(request)
        return render(request, self.template_name, context)

    def post(self, request):
        action = request.POST.get("action")
        if action == "create_menu_daily":
            return self._handle_menu_journalier_submission(request)
        if action == "create_menu_monthly":
            return self._handle_menu_mensuel_submission(request)
        if action == "toggle_presence":
            return self._handle_presence_toggle(request)

        messages.error(request, "Action non reconnue.")
        return redirect("cantine:prestataire_dashboard")

    def _handle_menu_journalier_submission(self, request):
        form = MenuJournalierForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            messages.success(request, "Menu du jour enregistré et visible par l'administration.")
            return redirect("cantine:prestataire_dashboard")
        messages.error(request, "Impossible d'enregistrer le menu du jour.")
        context = self._build_context(request, menu_form=form)
        return render(request, self.template_name, context, status=400)

    def _handle_menu_mensuel_submission(self, request):
        form = MenuMensuelForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            messages.success(request, "Menu du mois partagé avec l'administration.")
            return redirect("cantine:prestataire_dashboard")
        messages.error(request, "Le menu mensuel comporte des erreurs.")
        context = self._build_context(request, monthly_form=form)
        return render(request, self.template_name, context, status=400)

    def _handle_presence_toggle(self, request):
        student_id = request.POST.get("student_id")
        repas = request.POST.get("repas", PresenceRepas.TypeRepas.DEJEUNER)
        today = timezone.localdate()

        eleve = get_object_or_404(Eleve, pk=student_id, actif=True)
        menu_du_jour = get_menu_for_date(today)
        presence, created = PresenceRepas.objects.get_or_create(
            eleve=eleve, date=today, repas=repas
        )
        if not created:
            presence.present = not presence.present
            presence.heure_pointage = timezone.localtime().time() if presence.present else None
        else:
            presence.present = True
            presence.heure_pointage = timezone.localtime().time()
        presence.menu = menu_du_jour
        presence.save()

        messages.success(
            request,
            f"Présence mise à jour pour {eleve.prenom} {eleve.nom}.",
        )
        return redirect("cantine:prestataire_dashboard")

    def _build_context(
        self,
        request,
        menu_form=None,
        monthly_form=None,
    ):
        today = timezone.localdate()
        students = Eleve.objects.filter(actif=True).select_related("classe").order_by(
            "classe__nom", "nom"
        )
        grouped_students = defaultdict(list)
        for eleve in students:
            grouped_students[eleve.classe.nom].append(eleve)

        today_presence_ids = set(
            PresenceRepas.objects.filter(date=today, present=True).values_list(
                "eleve_id", flat=True
            )
        )

        return {
            "menu_form": menu_form or MenuJournalierForm(initial={"date": today}),
            "monthly_form": monthly_form or MenuMensuelForm(),
            "grouped_students": dict(grouped_students),
            "today": today,
            "today_presence_ids": today_presence_ids,
            "daily_menus": MenuJournalier.objects.order_by("-date")[:7],
            "monthly_menus": MenuMensuel.objects.order_by("-annee", "-mois")[:6],
        }


class ProfileView(LoginRequiredMixin, View):
    """Gestion du profil utilisateur (photo circulaire, contact, etc.)."""
    template_name = "cantines/profile.html"

    def get(self, request):
        profile = getattr(request.user, "profile", None)
        if profile is None:
            profile = UserProfile.objects.create(user=request.user)
        form = UserProfileForm(instance=profile)
        is_admin = profile.role == UserProfile.Role.ADMIN
        
        return render(
            request,
            self.template_name,
            {
                "form": form,
                "profile": profile,
                "is_admin": is_admin,
            },
        )

    def post(self, request):
        profile = getattr(request.user, "profile", None)
        if profile is None:
            profile = UserProfile.objects.create(user=request.user)
        is_admin = profile.role == UserProfile.Role.ADMIN
        
        # Sauvegarder la valeur originale du poste avant de créer le formulaire
        original_poste = profile.poste
        
        form = UserProfileForm(request.POST, request.FILES, instance=profile)
        
        if form.is_valid():
            # Si l'utilisateur n'est pas admin, restaurer la valeur originale du poste
            if not is_admin:
                form.instance.poste = original_poste
            form.save()
            messages.success(request, "Profil mis à jour avec succès.")
            return redirect("cantine:profile")
        messages.error(request, "Impossible de mettre à jour le profil.")
        return render(
            request,
            self.template_name,
            {
                "form": form,
                "profile": profile,
                "is_admin": is_admin,
            },
            status=400,
        )

User = get_user_model()


def ensure_profile(user):
    profile = getattr(user, "profile", None)
    if profile is None:
        profile, _ = UserProfile.objects.get_or_create(user=user)
    return profile


def subtract_months(reference_date: date, months: int) -> date:
    year = reference_date.year + (reference_date.month - months - 1) // 12
    month = (reference_date.month - months - 1) % 12 + 1
    day = min(reference_date.day, calendar.monthrange(year, month)[1])
    return date(year, month, day)


def get_menu_for_date(target_date: date):
    return (
        MenuJournalier.objects.filter(date=target_date)
        .select_related()
        .first()
    )


def get_dashboard_stats():
    today = timezone.localdate()
    start_month = today.replace(day=1)
    total_eleves = Eleve.objects.count()
    eleves_actifs = Eleve.objects.filter(actif=True).count()
    repas_aujourd_hui = PresenceRepas.objects.filter(date=today, present=True).count()
    repas_ce_mois = PresenceRepas.objects.filter(date__gte=start_month, present=True).count()
    factures_en_attente = AbonnementCantine.objects.filter(solde__lt=0).count()
    eleves_inscrits_mois = Eleve.objects.filter(date_inscription__gte=start_month).count()
    total_classes = Classe.objects.count()
    return {
        "total_eleves": total_eleves,
        "eleves_actifs": eleves_actifs,
        "repas_aujourd_hui": repas_aujourd_hui,
        "repas_ce_mois": repas_ce_mois,
        "factures_en_attente": factures_en_attente,
        "eleves_inscrits_mois": eleves_inscrits_mois,
        "total_students": total_eleves,
        "active_students": eleves_actifs,
        "todays_meals": repas_aujourd_hui,
        "total_classes": total_classes,
        "month_presence": repas_ce_mois,
    }


def get_alertes(today: date):
    alertes = []
    solde_negatif = AbonnementCantine.objects.filter(solde__lt=0).count()
    if solde_negatif:
        alertes.append(
            {
                "type": "warning",
                "message": f"{solde_negatif} élève(s) présentent un solde négatif.",
            }
        )
    if not MenuJournalier.objects.filter(date=today).exists():
        alertes.append(
            {
                "type": "info",
                "message": "Aucun menu n'a été publié pour aujourd'hui.",
            }
        )
    return alertes


def get_attendance_trend(days: int = 7):
    start_date = timezone.localdate() - timedelta(days=days - 1)
    data = (
        PresenceRepas.objects.filter(date__gte=start_date)
        .values("date")
        .annotate(
            total=Count("id"),
            presents=Count("id", filter=Q(present=True)),
        )
        .order_by("date")
    )
    trend = []
    for entry in data:
        total = entry["total"] or 0
        ratio = round((entry["presents"] / total) * 100, 1) if total else 0
        trend.append(
            {
                "date": entry["date"],
                "presents": entry["presents"],
                "ratio": ratio,
            }
        )
    return trend


def get_financial_stats():
    first_day_month = timezone.localdate().replace(day=1)
    expenses = (
        DepenseCantine.objects.filter(date__gte=first_day_month)
        .values("categorie")
        .annotate(total=Sum("montant"))
    )
    categories = []
    total_expenses = 0
    for item in expenses:
        code = item["categorie"]
        total = item["total"] or 0
        try:
            label = DepenseCantine.Categorie(code).label
        except ValueError:
            label = code.replace("_", " ").title()
        categories.append({"code": code, "label": label, "total": total})
        total_expenses += total
    return {"categories": categories, "total": total_expenses}


def get_repas_recents(limit: int = 8):
    return (
        PresenceRepas.objects.filter(present=True)
        .select_related("eleve", "eleve__classe", "menu")
        .order_by("-date", "-heure_pointage")[:limit]
    )


def get_repas_par_jour_data(days: int = 30):
    today = timezone.localdate()
    start_date = today - timedelta(days=days - 1)
    raws = (
        PresenceRepas.objects.filter(date__gte=start_date, present=True)
        .values("date")
        .annotate(count=Count("id"))
        .order_by("date")
    )
    return json.dumps([
        {"date": entry["date"].strftime("%d/%m"), "count": entry["count"]} for entry in raws
    ])


def get_reporting_overview():
    report = []
    presence_by_class = (
        PresenceRepas.objects.filter(present=True)
        .values("eleve__classe__nom")
        .annotate(total=Count("id"))
        .order_by("-total")
    )
    for item in presence_by_class[:5]:
        report.append({"classe": item["eleve__classe__nom"], "total": item["total"]})
    return report


def build_dashboard_context():
    today = timezone.localdate()
    context = {
        "stats": get_dashboard_stats(),
        "alertes": get_alertes(today),
        "menu_du_jour": get_menu_for_date(today),
        "repas_recents": get_repas_recents(),
        "repas_par_jour_data": get_repas_par_jour_data(),
        "attendance_trend": get_attendance_trend(),
        "financial_stats": get_financial_stats(),
        "upcoming_menus": MenuJournalier.objects.filter(date__gte=today).order_by("date")[:6],
        "monthly_menus": MenuMensuel.objects.order_by("-annee", "-mois")[:6],
        "latest_students": Eleve.objects.select_related("classe").order_by("-date_inscription")[:5],
        "reporting": get_reporting_overview(),
        "today": today,
    }
    return context


def build_calendar_days(year: int, month: int):
    cal = calendar.Calendar(firstweekday=0)
    days = list(cal.itermonthdates(year, month))
    if not days:
        return []
    start = days[0]
    end = days[-1]
    menus = {
        menu.date: menu
        for menu in MenuJournalier.objects.filter(date__range=(start, end))
    }
    today = timezone.localdate()
    calendar_days = []
    for current_day in days:
        calendar_days.append(
            {
                "date": current_day,
                "day": current_day.day,
                "other_month": current_day.month != month,
                "is_today": current_day == today,
                "menu": menus.get(current_day),
            }
        )
    return calendar_days


class GlobalDashboardView(ProfileRequiredMixin, TemplateView):
    template_name = "cantines/dashboard.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        profile = ensure_profile(self.request.user)
        dashboard_context = build_dashboard_context()
        dashboard_context["is_admin"] = profile.role == UserProfile.Role.ADMIN
        context.update(dashboard_context)
        return context


class MenuListView(ProfileRequiredMixin, ListView):
    template_name = "cantines/menu_list.html"
    context_object_name = "menus"
    model = MenuJournalier
    paginate_by = 12

    def get_queryset(self):
        return MenuJournalier.objects.order_by("-date")

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        today = timezone.localdate()
        context["today"] = today
        context["menu_du_jour"] = get_menu_for_date(today)
        return context


class MenuCreateView(RoleRequiredMixin, CreateView):
    required_role = UserProfile.Role.PRESTATAIRE
    template_name = "cantines/menu_form.html"
    form_class = MenuJournalierForm
    success_url = reverse_lazy("cantine:menu_list")

    def form_valid(self, form):
        try:
            response = super().form_valid(form)
        except IntegrityError:
            form.add_error("date", "Un menu existe déjà pour cette date.")
            return self.form_invalid(form)
        messages.success(self.request, "Menu journalier enregistré.")
        return response


class MenuUpdateView(RoleRequiredMixin, UpdateView):
    required_role = UserProfile.Role.PRESTATAIRE
    template_name = "cantines/menu_form.html"
    form_class = MenuJournalierForm
    model = MenuJournalier
    success_url = reverse_lazy("cantine:menu_list")

    def form_valid(self, form):
        try:
            response = super().form_valid(form)
        except IntegrityError:
            form.add_error("date", "Un menu existe déjà pour cette date.")
            return self.form_invalid(form)
        messages.success(self.request, "Menu mis à jour avec succès.")
        return response


class MenuDeleteView(RoleRequiredMixin, DeleteView):
    required_role = UserProfile.Role.PRESTATAIRE
    model = MenuJournalier
    template_name = "cantines/menu_confirm_delete.html"
    success_url = reverse_lazy("cantine:menu_list")

    def delete(self, request, *args, **kwargs):
        messages.success(request, "Menu supprimé avec succès.")
        return super().delete(request, *args, **kwargs)


class MenuCalendarView(ProfileRequiredMixin, TemplateView):
    template_name = "cantines/menu_calendar.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        today = timezone.localdate()
        year = int(self.request.GET.get("year", today.year))
        month = int(self.request.GET.get("month", today.month))
        if month < 1:
            month = 12
            year -= 1
        if month > 12:
            month = 1
            year += 1
        context.update(
            {
                "year": year,
                "month": f"{month:02d}",
                "calendar_days": build_calendar_days(year, month),
            }
        )
        return context


class DecompteJournalierView(RoleRequiredMixin, TemplateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/decompte_journalier.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        try:
            date_str = self.request.GET.get("date")
            target_date = datetime.strptime(date_str, "%Y-%m-%d").date() if date_str else timezone.localdate()
        except ValueError:
            target_date = timezone.localdate()
        repas = (
            PresenceRepas.objects.filter(date=target_date, present=True)
            .select_related("eleve", "eleve__classe", "menu")
            .order_by("eleve__nom")
        )
        context.update(
            {
                "date": target_date,
                "menu": get_menu_for_date(target_date),
                "nombre_repas": repas.count(),
                "eleves_servis": repas.values("eleve_id").distinct().count(),
                "repas": repas,
            }
        )
        return context


class DecompteMensuelView(RoleRequiredMixin, TemplateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/decompte_mensuel.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        today = timezone.localdate()
        mois = int(self.request.GET.get("mois", today.month))
        annee = int(self.request.GET.get("annee", today.year))
        first_day = date(annee, mois, 1)
        last_day = date(annee, mois, calendar.monthrange(annee, mois)[1])
        repas = (
            PresenceRepas.objects.filter(date__range=(first_day, last_day), present=True)
            .select_related("eleve", "eleve__classe", "menu")
            .order_by("date")
        )
        repas_par_jour = (
            repas.values("date")
            .annotate(total=Count("id"))
            .order_by("date")
        )
        context.update(
            {
                "mois": mois,
                "annee": annee,
                "nombre_repas": repas.count(),
                "nombre_jours_travail": repas.values("date").distinct().count(),
                "eleves_servis": repas.values("eleve_id").distinct().count(),
                "repas_par_jour": {entry["date"].strftime("%d/%m/%Y"): entry["total"] for entry in repas_par_jour},
                "repas": repas,
            }
        )
        return context


class DetailPlatsServisView(RoleRequiredMixin, TemplateView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/detail_plats_servis.html"

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        queryset = PresenceRepas.objects.filter(present=True).select_related("eleve", "eleve__classe", "menu")
        eleve_id = self.request.GET.get("eleve")
        date_debut = self.request.GET.get("date_debut")
        date_fin = self.request.GET.get("date_fin")
        if eleve_id:
            queryset = queryset.filter(eleve_id=eleve_id)
        if date_debut:
            queryset = queryset.filter(date__gte=date_debut)
        if date_fin:
            queryset = queryset.filter(date__lte=date_fin)
        try:
            eleve_selected = int(eleve_id) if eleve_id else None
        except (TypeError, ValueError):
            eleve_selected = None
        eleves_queryset = Eleve.objects.order_by("nom", "prenom")
        selected_eleve_name = None
        if eleve_selected:
            selected_eleve = eleves_queryset.filter(pk=eleve_selected).first()
            if selected_eleve:
                selected_eleve_name = str(selected_eleve)
        eleves_concernes = queryset.values("eleve_id").distinct().count()
        context.update(
            {
                "eleves": eleves_queryset,
                "eleve_selected": eleve_selected,
                "eleve_selected_label": selected_eleve_name,
                "date_debut": date_debut or "",
                "date_fin": date_fin or "",
                "repas": queryset.order_by("-date"),
                "eleves_concernes": eleves_concernes,
                "repas_total": queryset.count(),
            }
        )
        return context


class PrestataireListView(RoleRequiredMixin, ListView):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/prestataire_list.html"
    model = UserProfile
    context_object_name = "prestataires"
    paginate_by = 12

    def get_queryset(self):
        queryset = UserProfile.objects.select_related("user").order_by("user__username")
        role = self.request.GET.get("role")
        if role in dict(UserProfile.Role.choices):
            queryset = queryset.filter(role=role)
        actif = self.request.GET.get("actif")
        if actif == "1":
            queryset = queryset.filter(user__is_active=True)
        elif actif == "0":
            queryset = queryset.filter(user__is_active=False)
        return queryset

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        params = self.request.GET.copy()
        view_mode = params.get("view", "grid")
        if view_mode not in {"list", "grid"}:
            view_mode = "grid"
        params.pop("page", None)
        list_params = params.copy()
        grid_params = params.copy()
        list_params["view"] = "list"
        grid_params["view"] = "grid"
        context.update(
            {
                "view_mode": view_mode,
                "list_view_url": f"?{list_params.urlencode()}" if list_params else "?view=list",
                "grid_view_url": f"?{grid_params.urlencode()}" if grid_params else "?view=grid",
            }
        )
        return context


class PrestataireFormMixin(RoleRequiredMixin):
    required_role = UserProfile.Role.ADMIN
    template_name = "cantines/prestataire_form.html"
    success_url = reverse_lazy("cantine:prestataire_list")
    form_class = PrestataireForm


class PrestataireCreateView(PrestataireFormMixin, FormView):
    def form_valid(self, form):
        user, profile, generated_password = form.save()
        if generated_password:
            messages.success(
                self.request,
                f"Prestataire créé avec succès. Mot de passe temporaire : {generated_password}",
            )
        else:
            messages.success(self.request, "Prestataire créé avec succès.")
        return super().form_valid(form)


class PrestataireUpdateView(PrestataireFormMixin, FormView):
    def get_form_kwargs(self):
        kwargs = super().get_form_kwargs()
        profile = get_object_or_404(UserProfile, pk=self.kwargs["pk"])
        kwargs["user_instance"] = profile.user
        kwargs["profile_instance"] = profile
        kwargs["initial"] = {
            "username": profile.user.username,
            "email": profile.user.email,
            "first_name": profile.user.first_name,
            "last_name": profile.user.last_name,
            "role": profile.role,
            "organisation": profile.poste,
            "telephone": profile.contact,
            "actif": profile.user.is_active,
        }
        return kwargs

    def form_valid(self, form):
        user, profile, _ = form.save()
        messages.success(self.request, "Prestataire mis à jour avec succès.")
        return super().form_valid(form)


class PrestataireDeleteView(RoleRequiredMixin, DeleteView):
    required_role = UserProfile.Role.ADMIN
    model = UserProfile
    template_name = "cantines/prestataire_confirm_delete.html"
    success_url = reverse_lazy("cantine:prestataire_list")

    def delete(self, request, *args, **kwargs):
        profile = self.get_object()
        user = profile.user
        response = super().delete(request, *args, **kwargs)
        user.delete()
        messages.success(request, "Prestataire supprimé avec succès.")
        return response
