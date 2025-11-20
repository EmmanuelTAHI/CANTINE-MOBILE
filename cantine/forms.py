from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import AuthenticationForm
from django.utils import timezone

from .models import (
    Classe,
    Eleve,
    MenuJournalier,
    MenuMensuel,
    UserProfile,
)


class StudentForm(forms.ModelForm):
    """Formulaire d'inscription ou mise à jour d'un élève."""

    class Meta:
        model = Eleve
        fields = [
            "matricule",
            "nom",
            "prenom",
            "classe",
            "date_inscription",
            "photo",
            "actif",
            "contact_parent",
            "email_parent",
            "notes",
        ]
        widgets = {
            "matricule": forms.TextInput(
                attrs={
                    "placeholder": "Ex: HEG-2024-001",
                    "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                }
            ),
            "nom": forms.TextInput(
                attrs={
                    "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                }
            ),
            "prenom": forms.TextInput(
                attrs={
                    "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                }
            ),
            "classe": forms.Select(
                attrs={
                    "class": "select select-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                }
            ),
            "date_inscription": forms.DateInput(
                attrs={
                    "type": "date",
                    "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                }
            ),
            "actif": forms.CheckboxInput(
                attrs={
                    "class": "toggle toggle-primary [--tglbg:#cbd5f5] checked:bg-heg-violet",
                }
            ),
            "contact_parent": forms.TextInput(
                attrs={
                    "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                    "placeholder": "Téléphone du parent",
                }
            ),
            "email_parent": forms.EmailInput(
                attrs={
                    "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                    "placeholder": "parent@example.com",
                }
            ),
            "notes": forms.Textarea(
                attrs={
                    "rows": 4,
                    "class": "textarea textarea-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
                }
            ),
            "photo": forms.ClearableFileInput(
                attrs={
                    "class": "file-input file-input-bordered w-full border-gray-300 focus:border-heg-violet",
                }
            ),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["date_inscription"].initial = (
            self.initial.get("date_inscription") or timezone.localdate()
        )
        self.fields["classe"].queryset = Classe.objects.order_by("nom")
        self.fields["contact_parent"].label = "Téléphone parent"
        self.fields["email_parent"].label = "Email parent"
        self.fields["photo"].label = "Photo de profil"


class StudentFilterForm(forms.Form):
    """Filtres pour la liste des élèves dans le tableau."""

    STATUT_CHOICES = (
        ("", "Tous les statuts"),
        ("actif", "Actifs"),
        ("inactif", "Inactifs"),
    )

    recherche = forms.CharField(
        required=False,
        label="Recherche",
        widget=forms.TextInput(
            attrs={
                "placeholder": "Nom, prénom, matricule…",
                "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
            }
        ),
    )
    classe = forms.ModelChoiceField(
        queryset=Classe.objects.none(),
        required=False,
        empty_label="Toutes les classes",
        widget=forms.Select(
            attrs={
                "class": "select select-bordered border-[#58595b] focus:border-[#902c8e] w-full",
            }
        ),
    )
    statut = forms.ChoiceField(
        required=False,
        choices=STATUT_CHOICES,
        widget=forms.Select(
            attrs={
                "class": "select select-bordered border-[#58595b] focus:border-[#902c8e] w-full",
            }
        ),
    )

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["classe"].queryset = Classe.objects.order_by("nom")


class MenuJournalierForm(forms.ModelForm):
    """Création et mise à jour du menu journalier."""

    class Meta:
        model = MenuJournalier
        fields = [
            "date",
            "entree",
            "plat_principal",
            "accompagnement",
            "dessert",
            "boisson",
            "commentaires",
            "photo",
        ]
        widgets = {
            "date": forms.DateInput(
                attrs={
                    "type": "date",
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "entree": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "plat_principal": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "accompagnement": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "dessert": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "boisson": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "commentaires": forms.Textarea(
                attrs={
                    "rows": 3,
                    "class": "textarea textarea-bordered border-[#58595b] focus:border-[#902c8e] w-full bg-white text-heg-gris",
                }
            ),
            "photo": forms.ClearableFileInput(
                attrs={
                    "class": "file-input file-input-bordered w-full border-[#58595b] focus:border-[#902c8e]",
                }
            ),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["date"].initial = (
            self.initial.get("date") or timezone.localdate()
        )


class ClasseForm(forms.ModelForm):
    """Création de classe côté administration."""

    class Meta:
        model = Classe
        fields = ["nom", "niveau", "responsable"]
        widgets = {
            "nom": forms.TextInput(
                attrs={
                    "placeholder": "Ex : 6ème A",
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "niveau": forms.TextInput(
                attrs={
                    "placeholder": "Collège, Lycée…",
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "responsable": forms.TextInput(
                attrs={
                    "placeholder": "Nom du professeur principal",
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
        }


class MenuMensuelForm(forms.ModelForm):
    """Planification du menu du mois (prestataire ou administration)."""

    class Meta:
        model = MenuMensuel
        fields = [
            "titre",
            "mois",
            "annee",
            "description",
            "couverture",
            "document",
        ]
        widgets = {
            "titre": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "mois": forms.Select(
                attrs={
                    "class": "select select-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "annee": forms.NumberInput(
                attrs={
                    "min": 2020,
                    "max": 2100,
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "description": forms.Textarea(
                attrs={
                    "rows": 4,
                    "class": "textarea textarea-bordered border-[#58595b] focus:border-[#902c8e] w-full bg-white text-heg-gris",
                }
            ),
            "couverture": forms.ClearableFileInput(
                attrs={
                    "class": "file-input file-input-bordered w-full border-[#58595b] focus:border-[#902c8e]",
                }
            ),
            "document": forms.ClearableFileInput(
                attrs={
                    "class": "file-input file-input-bordered w-full border-[#58595b] focus:border-[#902c8e]",
                }
            ),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields["annee"].initial = timezone.now().year
        self.fields["mois"].initial = timezone.now().month


class UserProfileForm(forms.ModelForm):
    """Mise à jour des informations personnelles et de contact."""

    class Meta:
        model = UserProfile
        fields = ["avatar", "contact", "poste", "bio"]
        widgets = {
            "avatar": forms.ClearableFileInput(
                attrs={
                    "class": "file-input file-input-bordered w-full border-[#58595b] focus:border-[#902c8e]",
                }
            ),
            "contact": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "poste": forms.TextInput(
                attrs={
                    "class": "input input-bordered border-[#58595b] focus:border-[#902c8e] w-full",
                }
            ),
            "bio": forms.Textarea(
                attrs={
                    "rows": 4,
                    "class": "textarea textarea-bordered border-[#58595b] focus:border-[#902c8e] w-full bg-white text-heg-gris",
                }
            ),
        }


class RoleAuthenticationForm(AuthenticationForm):
    """Formulaire de connexion stylisé avec rappel du rôle."""

    username = forms.CharField(
        widget=forms.TextInput(
            attrs={
                "autofocus": True,
                "class": "input input-bordered w-full border-[#58595b] focus:border-[#902c8e]",
                "placeholder": "Identifiant ou e-mail",
            }
        )
    )
    password = forms.CharField(
        label="Mot de passe",
        strip=False,
        widget=forms.PasswordInput(
            attrs={
                "class": "input input-bordered w-full border-[#58595b] focus:border-[#902c8e]",
                "placeholder": "Mot de passe",
            }
        ),
    )


class EleveImportForm(forms.Form):
    fichier = forms.FileField(
        label="Fichier CSV",
        help_text="Format UTF-8, colonnes : matricule, prénom, nom, classe, téléphone, email.",
        widget=forms.ClearableFileInput(
            attrs={
                "accept": ".csv",
                "class": "file-input file-input-bordered w-full border-gray-300 focus:border-heg-violet",
            }
        ),
    )


class PrestataireForm(forms.Form):
    role = forms.ChoiceField(
        choices=UserProfile.Role.choices,
        widget=forms.Select(
            attrs={
                "class": "select select-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        ),
    )
    actif = forms.BooleanField(
        required=False,
        label="Compte actif",
        widget=forms.CheckboxInput(
            attrs={
                "class": "toggle toggle-primary [--tglbg:#cbd5f5] checked:bg-heg-violet",
            }
        ),
    )
    organisation = forms.CharField(
        required=False,
        label="Organisation",
        widget=forms.TextInput(
            attrs={
                "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        ),
    )
    telephone = forms.CharField(
        required=False,
        label="Téléphone",
        widget=forms.TextInput(
            attrs={
                "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        ),
    )
    username = forms.CharField(
        widget=forms.TextInput(
            attrs={
                "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        )
    )
    email = forms.EmailField(
        widget=forms.EmailInput(
            attrs={
                "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        )
    )
    first_name = forms.CharField(
        required=False,
        widget=forms.TextInput(
            attrs={
                "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        )
    )
    last_name = forms.CharField(
        required=False,
        widget=forms.TextInput(
            attrs={
                "class": "input input-bordered w-full bg-white border-gray-300 focus:border-heg-violet focus:outline-none",
            }
        )
    )

    def __init__(self, *args, **kwargs):
        self.user_instance = kwargs.pop("user_instance", None)
        self.profile_instance = kwargs.pop("profile_instance", None)
        super().__init__(*args, **kwargs)
        self.UserModel = get_user_model()
        if self.user_instance:
            self.fields["username"].initial = self.user_instance.username
            self.fields["email"].initial = self.user_instance.email
            self.fields["first_name"].initial = self.user_instance.first_name
            self.fields["last_name"].initial = self.user_instance.last_name
            self.fields["actif"].initial = self.user_instance.is_active
        if self.profile_instance:
            self.fields["role"].initial = self.profile_instance.role
            self.fields["organisation"].initial = self.profile_instance.poste
            self.fields["telephone"].initial = self.profile_instance.contact

    def save(self):
        user = self.user_instance
        profile = self.profile_instance
        generated_password = None
        if user is None:
            generated_password = self.UserModel.objects.make_random_password()
            user = self.UserModel.objects.create_user(
                username=self.cleaned_data["username"],
                email=self.cleaned_data["email"],
                password=generated_password,
                first_name=self.cleaned_data["first_name"],
                last_name=self.cleaned_data["last_name"],
            )
        else:
            user.username = self.cleaned_data["username"]
            user.email = self.cleaned_data["email"]
            user.first_name = self.cleaned_data["first_name"]
            user.last_name = self.cleaned_data["last_name"]
        user.is_active = self.cleaned_data["actif"]
        user.save()

        if profile is None:
            profile = UserProfile.objects.create(user=user)
        profile.role = self.cleaned_data["role"]
        profile.poste = self.cleaned_data["organisation"]
        profile.contact = self.cleaned_data["telephone"]
        profile.save()
        return user, profile, generated_password

