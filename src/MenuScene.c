#include "MenuScene.h"
#include "Text.h"
#include "Util.h"
#include "Event.h"
#include "Input.h"
#include "LevelScene.h"
#include "ControlsScene.h"
#include "main.h"

typedef struct {
    int level;
    int menuItem;
    SDL_Texture* logo;
    SDL_Renderer* renderer;
} MenuSceneState;

SDL_AppResult MenuScene_event(Scene* scene, SDL_Event* event) {
    MenuSceneState* mss = (MenuSceneState*)scene->state;
    Vec2 dir = {0, 0};
    Scene* newScene;

    switch (Input_fromEvent(event, true)) {
        case I_UP:    dir = V_UP; break;
        case I_DOWN:  dir = V_DOWN; break;
        case I_LEFT:  dir = V_LEFT; break;
        case I_RIGHT: dir = V_RIGHT; break;
        case I_BACK:  return SDL_APP_SUCCESS;
        case I_CONFIRM:
            switch (mss->menuItem) {
                case 1: SDL_PushEvent(&(SDL_Event){.user.type = EVENT_PUSH_SCENE, .user.data1 = LevelScene_create(mss->renderer, mss->level)}); break;
                case 2: SDL_PushEvent(&(SDL_Event){.user.type = EVENT_PUSH_SCENE, .user.data1 = ControlsScene_create()}); break;
                case 3: return SDL_APP_SUCCESS;
            }
        default: break;
    }

    mss->menuItem += dir.y;
    Util_wrap(&mss->menuItem, 4);

    if (mss->menuItem == 0) {
        mss->level += dir.x;
        Util_wrap(&mss->level, 10);
    }

    return SDL_APP_CONTINUE;
}

void MenuScene_draw(Scene* scene, SDL_Renderer* renderer) {
    MenuSceneState* mss = (MenuSceneState*)scene->state;

    char fmtStr[100];

    Util_drawWobbly(renderer, mss->logo, (Vec2){WINDOW_WIDTH/2 - mss->logo->w/2, 100});

    SDL_snprintf(fmtStr, sizeof(fmtStr)/sizeof(char), mss->menuItem == 0 ? "OLevel <%d>" : "Level %d", mss->level + 1);
    Text_drawCentered(renderer, fmtStr, 200);
    Text_drawCentered(renderer, mss->menuItem == 1 ? "OPlay" : "Play", 250);
    Text_drawCentered(renderer, mss->menuItem == 2 ? "OControls" : "Controls", 300);
    Text_drawCentered(renderer, mss->menuItem == 3 ? "OQuit" : "Quit", 350);
}

void MenuScene_free(Scene* scene) {
    MenuSceneState* mss = (MenuSceneState*)scene->state;
    
    SDL_DestroyTexture(mss->logo);
    SDL_free(scene->state);
    SDL_free(scene);
}

Scene* MenuScene_create(SDL_Renderer* renderer, int level, int menuItem) {
    Scene* scene = SDL_calloc(1, sizeof(Scene));
    *scene = (Scene){
        .state = SDL_calloc(1, sizeof(MenuSceneState)),
        .event = MenuScene_event,
        .draw = MenuScene_draw,
        .free = MenuScene_free
    };

    *((MenuSceneState*)scene->state) = (MenuSceneState){
        .renderer = renderer,
        .level = level,
        .menuItem = menuItem,
        .logo = Util_loadTexture(renderer, "logo.png")
    };

    return scene;
}
